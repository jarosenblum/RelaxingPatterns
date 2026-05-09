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

    private var players: [AmbientState: AVAudioPlayer] = [:]
    private var currentState: AmbientState?
    private var fadeTimer: Timer?

    private init() {
        loadPlayers()
    }

    private func loadPlayers() {
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
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0.0
                player.prepareToPlay()
                players[state] = player
            } catch {
                print("Failed to load \(fileName): \(error)")
            }
        }
    }

    func startDefaultAmbient() {
        transition(to: .normal)
    }

    func transition(to newState: AmbientState) {
        guard newState != currentState else { return }
        guard let newPlayer = players[newState] else { return }

        let oldPlayer = currentState.flatMap { players[$0] }

        if !newPlayer.isPlaying {
            newPlayer.volume = 0
            newPlayer.play()
        }

        currentState = newState
        crossfade(
            from: oldPlayer,
            to: newPlayer,
            duration: fadeDuration(for: newState),
            targetState: newState
        )
    }

    func stopAll(fadeOut: TimeInterval = 2.0) {
        fadeTimer?.invalidate()
        players.values.forEach {
            $0.stop()
            $0.volume = 0
        }
        currentState = nil
    }

    private func crossfade(
        from oldPlayer: AVAudioPlayer?,
        to newPlayer: AVAudioPlayer,
        duration: TimeInterval,
        targetState: AmbientState
    ) {
        fadeTimer?.invalidate()

        if !newPlayer.isPlaying {
            newPlayer.volume = 0
            newPlayer.play()
        }
        
        let steps = 60
        let interval = duration / Double(steps)
        let oldStartVolume = oldPlayer?.volume ?? 0
        let volumeTarget = targetVolume(for: targetState)
        var step = 0
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
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
                    
                    for (state, player) in self.players {
                        if state != self.currentState {
                            player.stop()
                            player.currentTime = 0
                            player.volume = 0.0
                        }
                    }
                    
                    newPlayer.volume = volumeTarget
                }
            }
        }
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
        players.values.forEach { player in
            if player.isPlaying {
                player.volume *= 0.7
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if let state = self.currentState,
               let player = self.players[state] {
                player.volume = self.targetVolume(for: state)
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
