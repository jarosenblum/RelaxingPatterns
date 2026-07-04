#if DEBUG
import Foundation
import Combine
@preconcurrency import AVFoundation

struct BreathDetectionDebugValues: Sendable {
    let rawAmplitude: Double
    let smoothedAmplitude: Double
    let possibleBreathEvent: Bool
    let estimatedCycleDuration: TimeInterval?
    let detectionConfidence: Double
}

@MainActor
final class ExperimentalMicrophoneBreathDetector: ObservableObject {
    static let shared = ExperimentalMicrophoneBreathDetector()

    enum Status: String {
        case off = "Mic off"
        case missingUsageDescription = "Mic key missing"
        case requestingPermission = "Requesting mic"
        case denied = "Mic denied"
        case running = "Mic running"
        case failed = "Mic failed"
    }

    @Published private(set) var status: Status = .off
    @Published private(set) var latestValues = BreathDetectionDebugValues(
        rawAmplitude: 0,
        smoothedAmplitude: 0,
        possibleBreathEvent: false,
        estimatedCycleDuration: nil,
        detectionConfidence: 0
    )
    @Published private(set) var micBreathPhase: Double = 0
    @Published private(set) var debugPhaseFloor: Double = 0.004
    @Published private(set) var debugPhaseCeiling: Double = 0.012

    private let engine = AVAudioEngine()
    private var smoothedAmplitude = 0.0
    private var noiseFloor = 0.004
    private var phaseFloor = 0.004
    private var phaseCeiling = 0.012
    private var lastEventDate: Date?
    private var cycleDurations: [TimeInterval] = []
    private var lastLogDate = Date.distantPast
    private var isRunning = false

    private init() {}

    func start() {
        guard !isRunning else { return }
        guard Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil else {
            status = .missingUsageDescription
            print("Breath mic debug: missing NSMicrophoneUsageDescription. Add the debug microphone usage string before starting mic analysis.")
            return
        }

        status = .requestingPermission

        Task {
            guard await AVAudioApplication.requestRecordPermission() else {
                status = .denied
                print("Breath mic debug: microphone permission denied.")
                return
            }

            do {
                try configureAudioSession()
                installInputTap()
                try engine.start()
                isRunning = true
                status = .running
                AmbientAudioManager.shared.recoverAmbientAfterDebugMicStart()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AmbientAudioManager.shared.recoverAmbientAfterDebugMicStart()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                    AmbientAudioManager.shared.recoverAmbientAfterDebugMicStart()
                }
                print("Breath mic debug: started.")
            } catch {
                status = .failed
                print("Breath mic debug: failed to start: \(error)")
                stop()
            }
        }
    }

    func stop() {
        guard isRunning || engine.isRunning else { return }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        status = .off
        micBreathPhase = 0
        phaseFloor = 0.004
        phaseCeiling = 0.012
        AmbientAudioManager.shared.restorePlaybackAfterDebugMicStop()
        print("Breath mic debug: stopped.")
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
        try session.overrideOutputAudioPort(.speaker)
    }

    private func installInputTap() {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { buffer, _ in
            let sampleRate = format.sampleRate
            let sampleCount = Int(buffer.frameLength)

            guard sampleRate > 0,
                  sampleCount > 0,
                  let channelData = buffer.floatChannelData?[0] else {
                return
            }

            let stats = Self.analyze(channelData: channelData, sampleCount: sampleCount)

            Task { @MainActor in
                self.consume(rawAmplitude: stats.rawAmplitude, spectralSoftness: stats.spectralSoftness)
            }
        }
    }

    private nonisolated static func analyze(
        channelData: UnsafePointer<Float>,
        sampleCount: Int
    ) -> (rawAmplitude: Double, spectralSoftness: Double) {
        var squareSum = 0.0
        var derivativeSum = 0.0
        var absoluteSum = 0.0
        var previous = Double(channelData[0])

        for index in 0..<sampleCount {
            let sample = Double(channelData[index])
            squareSum += sample * sample
            absoluteSum += abs(sample)

            if index > 0 {
                derivativeSum += abs(sample - previous)
            }

            previous = sample
        }

        let rms = sqrt(squareSum / Double(sampleCount))
        let averageAbsolute = max(absoluteSum / Double(sampleCount), 0.000_001)
        let spectralActivity = derivativeSum / Double(max(sampleCount - 1, 1)) / averageAbsolute
        let softness = 1.0 - min(max((spectralActivity - 0.18) / 0.62, 0), 1)

        return (rms, softness)
    }

    private func consume(rawAmplitude: Double, spectralSoftness: Double) {
        smoothedAmplitude = smoothedAmplitude * 0.92 + rawAmplitude * 0.08
        noiseFloor = min(max(noiseFloor * 0.995 + rawAmplitude * 0.005, 0.001), 0.05)

        let now = Date()
        let signalAboveFloor = max(smoothedAmplitude - noiseFloor * 1.8, 0)
        let amplitudeConfidence = min(signalAboveFloor / 0.035, 1)
        let detectionConfidence = min(max(amplitudeConfidence * spectralSoftness, 0), 1)
        let possibleBreathEvent = detectionConfidence > 0.42 && canRegisterEvent(at: now)

        let phaseAmplitude = smoothedAmplitude
        phaseFloor = min(phaseFloor * 0.998 + phaseAmplitude * 0.002, phaseAmplitude)
        phaseCeiling = max(phaseCeiling * 0.985 + phaseAmplitude * 0.015, phaseAmplitude + 0.002)
        debugPhaseFloor = phaseFloor
        debugPhaseCeiling = phaseCeiling

        let phaseRange = max(phaseCeiling - phaseFloor, 0.003)
        let normalizedPhase = (phaseAmplitude - phaseFloor) / phaseRange
        let targetMicBreathPhase = min(max(normalizedPhase * max(spectralSoftness, 0.45), 0), 1)
        micBreathPhase = micBreathPhase * 0.84 + targetMicBreathPhase * 0.16

        if possibleBreathEvent {
            registerEvent(at: now)
        }

        let values = BreathDetectionDebugValues(
            rawAmplitude: rawAmplitude,
            smoothedAmplitude: smoothedAmplitude,
            possibleBreathEvent: possibleBreathEvent,
            estimatedCycleDuration: estimatedCycleDuration,
            detectionConfidence: detectionConfidence
        )

        latestValues = values
        log(values, at: now)
    }

    private var estimatedCycleDuration: TimeInterval? {
        guard !cycleDurations.isEmpty else { return nil }

        return cycleDurations.reduce(0, +) / Double(cycleDurations.count)
    }

    private func canRegisterEvent(at date: Date) -> Bool {
        guard let lastEventDate else { return true }

        return date.timeIntervalSince(lastEventDate) > 1.6
    }

    private func registerEvent(at date: Date) {
        if let lastEventDate {
            let duration = date.timeIntervalSince(lastEventDate)

            if (2.0...12.0).contains(duration) {
                cycleDurations.append(duration)

                if cycleDurations.count > 5 {
                    cycleDurations.removeFirst(cycleDurations.count - 5)
                }
            }
        }

        lastEventDate = date
    }

    private func log(_ values: BreathDetectionDebugValues, at date: Date) {
        guard values.possibleBreathEvent || date.timeIntervalSince(lastLogDate) >= 1.0 else { return }

        lastLogDate = date

        let cycleText = values.estimatedCycleDuration.map { String(format: "%.2f", $0) } ?? "nil"
        print(
            String(
                format: "Breath mic debug: rawAmplitude=%.5f smoothedAmplitude=%.5f possibleBreathEvent=%@ estimatedCycleDuration=%@ detectionConfidence=%.2f",
                values.rawAmplitude,
                values.smoothedAmplitude,
                values.possibleBreathEvent ? "true" : "false",
                cycleText,
                values.detectionConfidence
            )
        )
    }
}
#endif
