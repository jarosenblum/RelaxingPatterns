import Foundation
@preconcurrency import AVFoundation

enum AmbientState: Equatable {
    case idle
    case normal
    case slowTouch
    case brightTouch
    case activeGesture
    case deep
    case reset
}

@MainActor
final class AmbientAudioManager {

    static let shared = AmbientAudioManager()

    private struct AmbientLoop {
        let file: AVAudioFile
        let node: AVAudioPlayerNode
    }

    private struct EvolutionStage {
        let time: TimeInterval
        let highShelfGain: Float
        let lowShelfGain: Float
        let reverbMix: Float
    }

    private var loops: [AmbientState: AmbientLoop] = [:]
    private let engine = AVAudioEngine()
    private let ambientMixer = AVAudioMixerNode()
    private let evolutionEQ = AVAudioUnitEQ(numberOfBands: 2)
    private let evolutionReverb = AVAudioUnitReverb()
    private var currentState: AmbientState?
    private var fadeTimer: Timer?
    private var evolutionTimer: Timer?
    private var currentHighShelfGain: Float = 0
    private var currentLowShelfGain: Float = 0
    private var currentReverbMix: Float = 2
    private var targetHighShelfGain: Float = 0
    private var targetLowShelfGain: Float = 0
    private var targetReverbMix: Float = 2

    private let evolutionStages: [EvolutionStage] = [
        EvolutionStage(time: 0, highShelfGain: 0.0, lowShelfGain: 0.0, reverbMix: 2.0),
        EvolutionStage(time: 300, highShelfGain: -0.8, lowShelfGain: 0.12, reverbMix: 2.8),
        EvolutionStage(time: 600, highShelfGain: -1.25, lowShelfGain: 0.2, reverbMix: 3.4),
        EvolutionStage(time: 1200, highShelfGain: -1.55, lowShelfGain: 0.26, reverbMix: 3.8)
    ]

    private init() {
        configureEngine()
        loadLoops()
    }

    private func configureEngine() {
        engine.attach(ambientMixer)
        engine.attach(evolutionEQ)
        engine.attach(evolutionReverb)

        let highShelf = evolutionEQ.bands[0]
        highShelf.filterType = .highShelf
        highShelf.frequency = 4200
        highShelf.bandwidth = 0.5
        highShelf.gain = currentHighShelfGain
        highShelf.bypass = false

        let lowShelf = evolutionEQ.bands[1]
        lowShelf.filterType = .lowShelf
        lowShelf.frequency = 240
        lowShelf.bandwidth = 0.6
        lowShelf.gain = currentLowShelfGain
        lowShelf.bypass = false

        evolutionReverb.loadFactoryPreset(.mediumHall)
        evolutionReverb.wetDryMix = currentReverbMix

        engine.connect(ambientMixer, to: evolutionEQ, format: nil)
        engine.connect(evolutionEQ, to: evolutionReverb, format: nil)
        engine.connect(evolutionReverb, to: engine.mainMixerNode, format: nil)
    }

    private func loadLoops() {
        let files: [AmbientState: String] = [
            .idle: "ambient_segment_01_165s",
            .normal: "ambient_segment_05_25s",
            .slowTouch: "ambient_segment_02_120s",
            .brightTouch: "ambient_segment_03_290s",
            .activeGesture: "ambient_segment_06_40s",
            .deep: "ambient_segment_04_200s",
            .reset: "ambient_segment_05_25s"
        ]

        for (state, fileName) in files {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
                print("Missing audio file: \(fileName).m4a")
                continue
            }

            do {
                let file = try AVAudioFile(forReading: url)
                let node = AVAudioPlayerNode()
                node.volume = 0.0
                engine.attach(node)
                engine.connect(node, to: ambientMixer, format: file.processingFormat)
                loops[state] = AmbientLoop(file: file, node: node)
            } catch {
                print("Failed to load \(fileName): \(error)")
            }
        }
    }

    func startDefaultAmbient() {
        configurePlaybackSession()
        startEngineIfNeeded()
        startEvolutionDriftIfNeeded()
        transition(to: .normal)
    }

    func transition(to newState: AmbientState) {
        guard newState != currentState else { return }
        guard let newLoop = loops[newState] else { return }

        startEngineIfNeeded()

        let oldLoop = currentState.flatMap { loops[$0] }
        startLoop(for: newState)

        currentState = newState
        crossfade(
            from: oldLoop?.node,
            to: newLoop.node,
            duration: fadeDuration(for: newState),
            targetState: newState
        )
    }

    func stopAll(fadeOut: TimeInterval = 2.0) {
        fadeTimer?.invalidate()
        evolutionTimer?.invalidate()
        evolutionTimer = nil
        loops.values.forEach { loop in
            loop.node.stop()
            loop.node.volume = 0
        }
        currentState = nil
    }

    func updateEvolution(elapsed: TimeInterval) {
        let target = evolutionTarget(for: elapsed)

        targetHighShelfGain = target.highShelfGain
        targetLowShelfGain = target.lowShelfGain
        targetReverbMix = target.reverbMix
        startEvolutionDriftIfNeeded()
    }

#if DEBUG
    func restorePlaybackAfterDebugMicStop() {
        configurePlaybackSession()
        recoverAmbientAfterDebugMicStart()
    }

    func testPhaseOneShift() {
        let target = evolutionTarget(for: 300)
        targetHighShelfGain = target.highShelfGain
        targetLowShelfGain = target.lowShelfGain
        targetReverbMix = target.reverbMix
        startEvolutionDriftIfNeeded()
    }

    func resetPhaseOneShift() {
        let target = evolutionTarget(for: 0)
        targetHighShelfGain = target.highShelfGain
        targetLowShelfGain = target.lowShelfGain
        targetReverbMix = target.reverbMix
        startEvolutionDriftIfNeeded()
    }

    func recoverAmbientAfterDebugMicStart() {
        guard let currentState else { return }

        engine.stop()
        engine.reset()

        for loop in loops.values {
            loop.node.stop()
            loop.node.volume = 0
        }

        do {
            try engine.start()
        } catch {
            print("Failed to recover ambient engine after debug mic start: \(error)")
            return
        }

        startLoop(for: currentState)
        loops[currentState]?.node.volume = targetVolume(for: currentState)
        startEvolutionDriftIfNeeded()
    }
#endif

    private func crossfade(
        from oldPlayer: AVAudioPlayerNode?,
        to newPlayer: AVAudioPlayerNode,
        duration: TimeInterval,
        targetState: AmbientState
    ) {
        fadeTimer?.invalidate()

        let steps = 60
        let interval = duration / Double(steps)
        let oldStartVolume = oldPlayer?.volume ?? 0.0
        let volumeTarget = targetVolume(for: targetState)
        var step = 0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                step += 1
                let progress = min(Double(step) / Double(steps), 1.0)
                
                let fadeIn = Float(pow(progress, 2.0))
                let fadeOut = Float(pow(1.0 - progress, 2.0))
                
                newPlayer.volume = volumeTarget * fadeIn
                oldPlayer?.volume = oldStartVolume * fadeOut
                
                if progress >= 1.0 {
                    self.fadeTimer?.invalidate()
                    self.fadeTimer = nil
                    
                    for (state, loop) in self.loops {
                        if state != self.currentState {
                            loop.node.stop()
                            loop.node.volume = 0.0
                        }
                    }
                    
                    newPlayer.volume = volumeTarget
                }
            }
        }
        }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }

        do {
            try engine.start()
        } catch {
            print("Failed to start ambient engine: \(error)")
        }
    }

    private func configurePlaybackSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to configure playback audio session: \(error)")
        }
    }

    private func startEvolutionDriftIfNeeded() {
        guard evolutionTimer == nil else { return }

        evolutionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.driftEvolutionTowardTarget()
            }
        }
    }

    private func startLoop(for state: AmbientState) {
        guard let loop = loops[state] else { return }

        if !loop.node.isPlaying {
            loop.node.volume = 0
            scheduleLoop(for: state)
            loop.node.play()
        }
    }

    private func scheduleLoop(for state: AmbientState) {
        guard let loop = loops[state] else { return }

        loop.node.scheduleFile(loop.file, at: nil) {
            Task { @MainActor in
                guard self.loops[state]?.node.isPlaying == true else { return }

                self.scheduleLoop(for: state)
            }
        }
    }

    private func evolutionTarget(for elapsed: TimeInterval) -> EvolutionStage {
        guard let first = evolutionStages.first else {
            return EvolutionStage(time: 0, highShelfGain: 0, lowShelfGain: 0, reverbMix: 2)
        }

        return evolutionStages.last(where: { elapsed >= $0.time }) ?? first
    }

    private func driftEvolutionTowardTarget() {
        currentHighShelfGain += (targetHighShelfGain - currentHighShelfGain) * 0.025
        currentLowShelfGain += (targetLowShelfGain - currentLowShelfGain) * 0.025
        currentReverbMix += (targetReverbMix - currentReverbMix) * 0.025

        evolutionEQ.bands[0].gain = currentHighShelfGain
        evolutionEQ.bands[1].gain = currentLowShelfGain
        evolutionReverb.wetDryMix = currentReverbMix
    }

    private func targetVolume(for state: AmbientState) -> Float {
        switch state {
        case .idle: return 0.04
        case .normal: return 0.06
        case .slowTouch: return 0.055
        case .brightTouch: return 0.075
        case .activeGesture: return 0.07
        case .deep: return 0.065
        case .reset: return 0.06
        }
    }
    private func fadeDuration(for state: AmbientState) -> TimeInterval {
        switch state {
        case .idle: return 2.0
        case .normal: return 2.0
        case .slowTouch: return 2.0
        case .brightTouch: return 1.5
        case .activeGesture: return 2.0
        case .deep: return 2.0
        case .reset: return 2.0
        }
    }
    
    func stateForGesture(touchVelocity: CGFloat, isPressing: Bool, isIdle: Bool) -> AmbientState {
        if isIdle { return .idle }
        if isPressing { return .activeGesture }
        if touchVelocity < 70 { return .slowTouch }
        if touchVelocity < 100 { return .brightTouch }
        return .activeGesture
    }
    
    func duckAmbient(duration: TimeInterval = 1.5) {
        loops.values.forEach { loop in
            if loop.node.isPlaying {
                loop.node.volume *= 0.7
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if let state = self.currentState,
               let loop = self.loops[state] {
                loop.node.volume = self.targetVolume(for: state)
            }
        }
    }
    
}
final class ToneGroupManager {

    static let shared = ToneGroupManager()

    private var toneFiles: [String] = []
    private var currentPlayer: AVAudioPlayer?
    private var lastPlayedFile: String?

    private let retriggerThreshold: TimeInterval = 0.5
    private let targetVolume: Float = 0.30

    private init() {
        loadToneGroups()
    }
    
    private func loadToneGroups() {
        // Adjust count to match your actual exported files
        toneFiles = (1...10).map { i in
            String(format: "tonegroup_%02d", i)
        }
    }

    func triggerToneGroup() {
        if let player = currentPlayer, player.isPlaying {
            let remaining = player.duration - player.currentTime

            guard remaining <= retriggerThreshold else {
                return
            }
        }

        guard let fileName = pickToneFile(),
              let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            print("Missing tonegroup file")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = targetVolume
            player.prepareToPlay()
            AmbientAudioManager.shared.duckAmbient()
            player.play()

            currentPlayer = player
            lastPlayedFile = fileName

        } catch {
            print("Failed to play tonegroup: \(error)")
        }
    }

    private func pickToneFile() -> String? {
        guard !toneFiles.isEmpty else { return nil }

        var candidates = toneFiles

        if let lastPlayedFile, candidates.count > 1 {
            candidates.removeAll { $0 == lastPlayedFile }
        }

        return candidates.randomElement()
    }
}
