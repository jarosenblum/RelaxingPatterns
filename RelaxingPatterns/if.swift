//
//  ContentView.swift
//  RelaxingPatterns
//
//  Created by Jason Rosenblum on 4/23/26.
//

import SwiftUI
import Combine

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

struct ContentView: View {
    @State private var circles: [SoftCircle] = []
    @State private var selectedPaletteIndex: Int = 0
    @State private var gradientShift: CGFloat = 0
    
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
            // keep tint, just nudge presence
            .fill(colors.first?.opacity(0.07) ?? Color.white.opacity(0.07))
            .frame(width: 460, height: 460)   // a bit larger = softer gradient
            .blur(radius: 110)                 // more diffuse = less hotspot
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(
                    x: gradientShift * 220 - 90,
                    y: gradientShift * 160 - 70
                )
                .allowsHitTesting(false)
            ForEach(circles) { circle in
                Circle()
                    .fill(circle.color.opacity(circle.opacity))
                    .frame(width: circle.size, height: circle.size)
                    .blur(radius: circle.blur)
                    .position(circle.position)
            }
            
            VStack {
                Spacer()

                Text("Tap or drag to create patterns\nLong press to intensify")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(circles.isEmpty ? 0.7 : 0.0))
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .animation(.easeOut(duration: 0.4), value: circles.isEmpty)

                Spacer()
            }
                .foregroundStyle(.white.opacity(circles.isEmpty ? 0.7 : 0.0))
                .font(.headline)
                .animation(.easeOut(duration: 0.4), value: circles.isEmpty)
            VStack {
                HStack {
                    Spacer()

                    Button("Color") {
                        selectedPaletteIndex = (selectedPaletteIndex + 1) % palettes.count
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    Button("Reset") {
                        circles.removeAll()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.trailing)
                }
                .overlay(
                    Capsule().stroke(.white.opacity(0.15), lineWidth: 1)
                )
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            addBurst(at: location)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    addTrailBurst(at: value.location)
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    intensifyField()
                }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                gradientShift = 0.45
            }
        }
        .onReceive(
            Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
        ) { _ in
            moveCircles()
        }
        
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
                circles[index].opacity *= 0.995   // slower fade
            } else {
                circles[index].opacity *= 0.982   // faster fade
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
