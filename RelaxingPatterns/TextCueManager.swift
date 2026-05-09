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

    @Published var currentMessage: String = ""
    @Published var isVisible: Bool = false

    private var sessionStart = Date()
    private var timer: Timer?
    private var shownMilestones: Set<TimeInterval> = []
    private var cueGeneration = 0
    private var pendingMessages: [String] = []
    private var isProcessingCue = false
    private let fadeInDuration = 1.4
    private let fadeOutDuration = 1.8
    private let visibleDuration = 4.5

    private let openingCues = [
        "Welcome.",
        "Take 1 minute… or 5.",
        "Pause the endless scroll.",
        "You are okay.",
        "This is all there is right now."
    ]

    private let orientationCues = [
        "Listen to the music.",
        "Tap or drag...and hear what changes.",
        "Watch the patterns move away.",
        "Let your attention follow the circles.",
        "Press into the screen to deepen the sound"
    ]

    private let sparseCues = [
        "Let your breath slow naturally.",
        "If your mind wanders, return to the motion.",
        "Nothing needs solving right now.",
        "Just watch the patterns drift.",
        "You can stay with this moment."
    ]
    
    private let milestoneCues: [(time: TimeInterval, message: String)] = [
        (30, "You’ve been here for 30 seconds."),
        (60, "You’ve been here for 1 minute."),
        (300, "5 minutes have passed. You’re doing great."),
        (600, "10 minutes. Notice if anything feels quieter."),
        (1200, "20 minutes. You gave yourself real space.")
    ]

    private init() {}

    func startSession() {
        sessionStart = Date()
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
        guard Int(Date().timeIntervalSince(sessionStart)) % 30 == 0 else { return }

        let cue = sparseCues.randomElement() ?? "Stay with the motion."
        show(cue)
    }

    func show(_ message: String) {
        pendingMessages.append(message)
        processNextCueIfNeeded()
    }

    private func processNextCueIfNeeded() {
        guard !isProcessingCue, !pendingMessages.isEmpty else { return }

        cueGeneration += 1
        let generation = cueGeneration
        let message = pendingMessages.removeFirst()
        isProcessingCue = true
        currentMessage = message

        withAnimation(.easeInOut(duration: fadeInDuration)) {
            isVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + fadeInDuration + visibleDuration) {
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
