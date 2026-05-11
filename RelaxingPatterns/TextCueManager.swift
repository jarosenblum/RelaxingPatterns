//
//  TextCueManager.swift
//  RelaxingPatterns
//
//  Created by Jason Rosenblum on 5/8/26.
//


import Foundation
import SwiftUI
import Combine

@MainActor
final class TextCueManager: ObservableObject {
    static let shared = TextCueManager()

    private struct CueMessage {
        let message: String
        let visibleDuration: TimeInterval
    }

    @Published var currentMessage: String = ""
    @Published var isVisible: Bool = false
    @Published private(set) var sessionElapsed: TimeInterval = 0

    private var sessionStart = Date()
    private var timer: Timer?
    private var shownMilestones: Set<TimeInterval> = []
    private var cueGeneration = 0
    private var pendingMessages: [CueMessage] = []
    private var isProcessingCue = false
    private let fadeInDuration = 1.4
    private let fadeOutDuration = 1.8
    private let visibleDuration = 4.5

    private let openingCues = [
        "Welcome.",
        "Take 1 minute… or 5.",
        "Tap gently.",
        "Tap slowly. Pause the endless scroll.",
        "You are Ok. This is all there is right now. Just tap."
    ]

    private let orientationCues = [
        "Listen to the music.",
        "Gently tap and drag...and hear what changes.",
        "Watch the patterns move away.",
        "Let your attention follow the circles.",
        "Tap and hold to deepen the sound"
    ]

    private let sparseCues = [
        "Let your breath slow naturally.",
        "If your mind wanders, return to the motion.",
        "Nothing needs solving right now.",
        "Just watch the patterns drift.",
        "You can stay with this moment."
    ]
    
    private let milestoneCues: [(time: TimeInterval, message: String)] = [
        (60, "Let your breath slow naturally."),
        (180, "3 minutes. Let your breath slow naturally."),
        (300, "5 minutes have passed. You’re doing great."),
        (600, "10 minutes. Notice if anything feels quieter."),
        (1200, "20 minutes. You gave yourself real space.")
    ]

    private init() {}

    func startSession() {
        sessionStart = Date()
        sessionElapsed = 0
        shownMilestones.removeAll()
        pendingMessages.removeAll()
        isProcessingCue = false
        currentMessage = ""
        isVisible = false

        timer?.invalidate()

        showOpeningSequence()

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                self.tick()
            }
        }
    }

    func stopSession() {
        timer?.invalidate()
        timer = nil
        hide()
    }

    private func tick() {
        let elapsed = Date().timeIntervalSince(sessionStart)
        sessionElapsed = elapsed
        AmbientAudioManager.shared.updateEvolution(elapsed: elapsed)

        if let milestone = milestoneCues.first(where: { elapsed >= $0.time && !shownMilestones.contains($0.time) }) {
            shownMilestones.insert(milestone.time)
            show(milestone.message)
            return
        }

        maybeShowSparseCue()
    }

    private func showOpeningSequence() {
        for (i, cue) in openingCues.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 6.0) {
                self.show(cue)
            }
        }

        let orientationStart = Double(openingCues.count) * 6.0 + 3.0

        for (i, cue) in orientationCues.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + orientationStart + Double(i) * 6.0) {
                self.show(cue)
            }
        }
    }

    private func maybeShowSparseCue() {
        // Approximately one sparse cue every ~30 seconds
        guard Date().timeIntervalSince(sessionStart) >= 300 else { return }
        guard Int(Date().timeIntervalSince(sessionStart)) % 30 == 0 else { return }

        let cue = sparseCues.randomElement() ?? "Stay with the motion."
        show(cue)
    }

    func show(_ message: String) {
        pendingMessages.append(CueMessage(message: message, visibleDuration: visibleDuration))
        processNextCueIfNeeded()
    }

    func showPacingCue() -> Bool {
        guard !isProcessingCue, pendingMessages.isEmpty else { return false }

        let cue = [
            "Notice what happens when you slow down.",
            "Let the patterns drift a little longer."
        ].randomElement() ?? "Let the patterns drift a little longer."

        pendingMessages.append(CueMessage(message: cue, visibleDuration: 8.0))
        processNextCueIfNeeded()
        return true
    }

    private func processNextCueIfNeeded() {
        guard !isProcessingCue, !pendingMessages.isEmpty else { return }

        cueGeneration += 1
        let generation = cueGeneration
        let cue = pendingMessages.removeFirst()
        isProcessingCue = true
        currentMessage = cue.message

        withAnimation(.easeInOut(duration: fadeInDuration)) {
            isVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + fadeInDuration + cue.visibleDuration) {
            guard generation == self.cueGeneration else { return }

            withAnimation(.easeInOut(duration: self.fadeOutDuration)) {
                self.isVisible = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.fadeOutDuration) {
                guard generation == self.cueGeneration else { return }

                self.currentMessage = ""
                self.isProcessingCue = false
                self.processNextCueIfNeeded()
            }
        }
    }

    private func hide() {
        cueGeneration += 1
        pendingMessages.removeAll()
        isProcessingCue = false
        let generation = cueGeneration

        withAnimation(.easeInOut(duration: 1.0)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard generation == self.cueGeneration else { return }

            self.currentMessage = ""
        }
    }
}
