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
    let size: CGFloat
    let color: Color
    let opacity: Double
    let blur: CGFloat
    let driftX: CGFloat
    let driftY: CGFloat
}

struct ContentView: View {
    @State private var circles: [SoftCircle] = []
    @State private var selectedPaletteIndex: Int = 0
    
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
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.45), value: selectedPaletteIndex)
            .ignoresSafeArea()
            
            ForEach(circles) { circle in
                Circle()
                    .fill(circle.color.opacity(circle.opacity))
                    .frame(width: circle.size, height: circle.size)
                    .blur(radius: circle.blur)
                    .position(circle.position)
            }
            
            if circles.isEmpty {
                Text("Tap to create a soft burst")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.headline)
            }
            VStack {
                HStack {
                    Spacer()

                    Button("Palette") {
                        selectedPaletteIndex = (selectedPaletteIndex + 1) % palettes.count
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())

                    Button("Clear") {
                        circles.removeAll()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
                    .padding(.trailing)
                }
                
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
                driftY: CGFloat.random(in: -0.8...0.8)
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
        let newCircles = (0..<3).map { _ in
            let jitterX = CGFloat.random(in: -25...25)
            let jitterY = CGFloat.random(in: -25...25)
            
            return SoftCircle(
                position: CGPoint(
                    x: location.x + jitterX,
                    y: location.y + jitterY
                ),
                size: CGFloat.random(in: 20...80),
                color: colors.randomElement() ?? .cyan,
                opacity: Double.random(in: 0.10...0.35),
                blur: CGFloat.random(in: 4...12),
                driftX: CGFloat.random(in: -1.4...1.4),
                driftY: CGFloat.random(in: -1.4...1.4)
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
        }
    }
}

#Preview {
    ContentView()
}
