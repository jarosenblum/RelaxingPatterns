//
//  ContentView.swift
//  RelaxingPatterns
//
//  Created by Jason Rosenblum on 4/23/26.
//

import SwiftUI

struct SoftCircle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
    let blur: CGFloat
}

struct ContentView: View {
    @State private var circles: [SoftCircle] = []
    
    private let colors: [Color] = [.cyan, .pink, .purple, .orange, .green, .blue]
    
    var body: some View {
        ZStack {
            Color.black
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

                    Button("Clear") {
                        circles.removeAll()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
                    .padding()
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

    }
    
    private func addBurst(at location: CGPoint) {
        let newCircles = (0..<12).map { _ in
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
                blur: CGFloat.random(in: 6...20)
            )
        }
        
        circles.append(contentsOf: newCircles)
        
        if circles.count > 250 {
            circles.removeFirst(circles.count - 250)
        }
    }
    private func addTrailBurst(at location: CGPoint) {
        let newCircles = (0..<4).map { _ in
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
                blur: CGFloat.random(in: 4...14)
            )
        }

        circles.append(contentsOf: newCircles)

        if circles.count > 250 {
            circles.removeFirst(circles.count - 250)
        }
    }
}

#Preview {
    ContentView()
}
