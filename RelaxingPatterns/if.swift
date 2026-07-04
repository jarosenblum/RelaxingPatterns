//
//  ContentView.swift
//  RelaxingPatterns
//
//  Created by Jason Rosenblum on 4/23/26.
//

import SwiftUI
import Combine
import AVFoundation

struct SoftCircle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    let color: Color
    var opacity: Double
    let blur: CGFloat
    let driftX: CGFloat
    let driftY: CGFloat
    let isTrail: Bool
}

extension View {
    func pillButtonStyle() -> some View {
        self
            .foregroundStyle(.white)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial.opacity(0.7))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .fixedSize()
    }
}

struct SessionTimeIndicator: View {
    let elapsed: TimeInterval

    private let milestones: [TimeInterval] = [30, 60, 120, 180, 300, 600, 1200]

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(.white.opacity(0.24))
                .frame(width: 18, height: 2)

            ForEach(milestones, id: \.self) { milestone in
                Circle()
                    .fill(.white.opacity(elapsed >= milestone ? 0.68 : 0.18))
                    .frame(width: 4, height: 4)
                    .animation(.easeInOut(duration: 1.2), value: elapsed >= milestone)
            }
        }
        .opacity(0.72)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct ContentView: View {
    @State private var circles: [SoftCircle] = []
    @State private var selectedPaletteIndex: Int = 0
    @State private var gradientShift: CGFloat = 0
    @State private var lastDragLocation: CGPoint?
    @State private var lastDragTime: Date?
    @State private var lastDeepenCueDate: Date?
    @State private var deepenResetWorkItem: DispatchWorkItem?
    @State private var tapTimestamps: [Date] = []
    @State private var lastPacingCueDate: Date?
    @StateObject private var textCueManager = TextCueManager.shared

    private let palettes: [[Color]] = [
        [.cyan, .pink, .purple, .orange, .green, .blue],
        [.cyan, .blue, .purple, .pink],
        [.orange, .yellow, .red, .pink],
        [.green, .mint, .cyan, .blue],
        [.white, .gray, .blue.opacity(0.7), .purple.opacity(0.6)]
    ]

    private var colors: [Color] {
        palettes[selectedPaletteIndex]
    }

    private var backgroundColors: [Color] {
        switch selectedPaletteIndex {
        case 0:
            return [
                Color(red: 0.12, green: 0.13, blue: 0.17),
                Color(red: 0.16, green: 0.14, blue: 0.15),
                Color(red: 0.11, green: 0.13, blue: 0.16)
            ]
        case 1:
            return [
                Color(red: 0.10, green: 0.10, blue: 0.16),
                Color(red: 0.13, green: 0.11, blue: 0.18),
                Color(red: 0.10, green: 0.12, blue: 0.17)
            ]
        case 2:
            return [
                Color(red: 0.16, green: 0.11, blue: 0.09),
                Color(red: 0.18, green: 0.13, blue: 0.10),
                Color(red: 0.12, green: 0.10, blue: 0.11)
            ]
        case 3:
            return [
                Color(red: 0.08, green: 0.13, blue: 0.13),
                Color(red: 0.10, green: 0.16, blue: 0.15),
                Color(red: 0.08, green: 0.11, blue: 0.14)
            ]
        default:
            return [
                Color(red: 0.12, green: 0.12, blue: 0.13),
                Color(red: 0.15, green: 0.15, blue: 0.17),
                Color(red: 0.11, green: 0.12, blue: 0.14)
            ]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: UnitPoint(x: 0.0 + gradientShift, y: 0.0),
                endPoint: UnitPoint(x: 1.0 - gradientShift, y: 1.0)
            )
            .animation(.easeInOut(duration: 0.45), value: selectedPaletteIndex)
            .ignoresSafeArea()

            Circle()
                .fill(colors.first?.opacity(0.07) ?? Color.white.opacity(0.07))
                .frame(width: 460, height: 460)
                .blur(radius: 110)
                .offset(x: gradientShift * 220 - 90, y: gradientShift * 160 - 70)
                .allowsHitTesting(false)

            ForEach(circles) { circle in
                Circle()
                    .fill(circle.color.opacity(circle.opacity))
                    .frame(width: circle.size, height: circle.size)
                    .blur(radius: circle.blur)
                    .position(circle.position)
            }

            VStack {
                SessionTimeIndicator(elapsed: textCueManager.sessionElapsed)
                    .padding(.top, 10)

                Spacer()
            }
            .allowsHitTesting(false)

            GeometryReader { proxy in
                Text(textCueManager.currentMessage)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: min(proxy.size.width - 48, 520))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(textCueManager.isVisible ? 1.0 : 0.0)
                    .allowsHitTesting(false)
            }
            .allowsHitTesting(false)

            VStack {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Button("Calm") {
                            AmbientAudioManager.shared.transition(to: .idle)
                        }
                        .pillButtonStyle()

                        Button("Flow") {
                            AmbientAudioManager.shared.transition(to: .normal)
                        }
                        .pillButtonStyle()

                        Button("Mood") {
                            selectedPaletteIndex = (selectedPaletteIndex + 1) % palettes.count
                            AmbientAudioManager.shared.transition(to: .slowTouch)
                        }
                        .pillButtonStyle()

                        Button("Reset") {
                            circles.removeAll()
                            AmbientAudioManager.shared.transition(to: .reset)
                        }
                        .pillButtonStyle()
                    }
                }
                .padding(.top, 28)
                .opacity(0.85)

                Spacer()
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if lastDragLocation == nil {
                        addBurst(at: value.location)
                        lastDragLocation = value.location
                        lastDragTime = Date()
                        recordTapPace()
                        ToneGroupManager.shared.triggerToneGroup()
                    } else {
                        addTrailBurst(at: value.location)
                    }
                }
                .onEnded { _ in
                    lastDragLocation = nil
                    lastDragTime = nil
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    deepenSound()
                    intensifyField()
                }
        )
        .onAppear {
            AmbientAudioManager.shared.startDefaultAmbient()
            TextCueManager.shared.startSession()
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                gradientShift = 0.45
            }
        }
        .onDisappear {
            deepenResetWorkItem?.cancel()
            AmbientAudioManager.shared.stopAll()
            TextCueManager.shared.stopSession()
        }
        .onReceive(
            Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
        ) { _ in
            moveCircles()
        }
    }

    private func recordTapPace() {
        let now = Date()
        tapTimestamps.append(now)
        tapTimestamps.removeAll { now.timeIntervalSince($0) > 4.0 }

        if let lastPacingCueDate,
           now.timeIntervalSince(lastPacingCueDate) < 90.0 {
            return
        }

        let tapsInOneSecond = tapTimestamps.filter { now.timeIntervalSince($0) <= 1.0 }.count
        let tapsInFourSeconds = tapTimestamps.count

        guard tapsInOneSecond > 3 || tapsInFourSeconds > 8 else { return }

        if TextCueManager.shared.showPacingCue() {
            lastPacingCueDate = now
        }
    }

    private func deepenSound() {
        let now = Date()

        if let lastDeepenCueDate,
           now.timeIntervalSince(lastDeepenCueDate) < 8.0 {
            return
        }

        lastDeepenCueDate = now
        AmbientAudioManager.shared.transition(to: .deep)
        TextCueManager.shared.show("Let the sound deepen.")

        deepenResetWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            AmbientAudioManager.shared.transition(to: .normal)
        }

        deepenResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: workItem)
    }

    private func addBurst(at location: CGPoint) {
        let newCircles = (0..<9).map { _ in
            let jitterX = CGFloat.random(in: -45...45)
            let jitterY = CGFloat.random(in: -45...45)

            return SoftCircle(
                position: CGPoint(
                    x: location.x + jitterX,
                    y: location.y + jitterY
                ),
                size: CGFloat.random(in: 40...150),
                color: colors.randomElement() ?? .cyan,
                opacity: Double.random(in: 0.15...0.45),
                blur: CGFloat.random(in: 6...20),
                driftX: CGFloat.random(in: -0.8...0.8),
                driftY: CGFloat.random(in: -0.8...0.8),
                isTrail: false
            )
        }

        withAnimation(.easeOut(duration: 0.35)) {
            circles.append(contentsOf: newCircles)
        }

        if circles.count > 120 {
            circles.removeFirst(circles.count - 120)
        }
    }

    private func addTrailBurst(at location: CGPoint) {
        let newCircles = (0..<5).map { _ in
            let jitterX = CGFloat.random(in: -25...25)
            let jitterY = CGFloat.random(in: -25...25)

            return SoftCircle(
                position: CGPoint(
                    x: location.x + jitterX,
                    y: location.y + jitterY
                ),
                size: CGFloat.random(in: 20...80),
                color: colors.randomElement() ?? .cyan,
                opacity: Double.random(in: 0.12...0.38),
                blur: CGFloat.random(in: 4...12),
                driftX: CGFloat.random(in: -1.4...1.4),
                driftY: CGFloat.random(in: -1.4...1.4),
                isTrail: true
            )
        }

        withAnimation(.easeOut(duration: 0.25)) {
            circles.append(contentsOf: newCircles)
        }

        if circles.count > 120 {
            circles.removeFirst(circles.count - 120)
        }
    }

    private func moveCircles() {
        for index in circles.indices {
            circles[index].position.x += circles[index].driftX
            circles[index].position.y += circles[index].driftY

            if circles[index].isTrail {
                circles[index].opacity *= 0.995
            } else {
                circles[index].opacity *= 0.982
            }
        }

        circles.removeAll { $0.opacity < 0.02 }
    }

    private func intensifyField() {
        withAnimation(.easeOut(duration: 0.45)) {
            for index in circles.indices {
                circles[index].size *= CGFloat.random(in: 1.06...1.16)
                circles[index].opacity = min(circles[index].opacity * 1.12, 0.48)
            }
        }
    }
}

#Preview {
    ContentView()
}
