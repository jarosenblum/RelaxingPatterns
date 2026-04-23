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
        .onReceive(
            Timer.publish(every: 0.08, on: .main, in: .common).autoconnect()
        ) { _ in
            moveCircles()
        }
        
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
                blur: CGFloat.random(in: 4...14),
                driftX: CGFloat.random(in: -1.4...1.4),
                driftY: CGFloat.random(in: -1.4...1.4)
            )
        }
        
        withAnimation(.easeOut(duration: 0.25)) {
            circles.append(contentsOf: newCircles)
        }
        
        if circles.count > 250 {
            circles.removeFirst(circles.count - 250)
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
