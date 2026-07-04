import Foundation
import Combine

struct BreathCycle: Equatable, Sendable {
    let inhaleDuration: TimeInterval
    let pauseDuration: TimeInterval
    let exhaleDuration: TimeInterval

    var totalDuration: TimeInterval {
        inhaleDuration + pauseDuration + exhaleDuration
    }

    nonisolated static let defaultGuided = BreathCycle(
        inhaleDuration: 4.0,
        pauseDuration: 1.0,
        exhaleDuration: 5.0
    )

    func breathPhase(at elapsed: TimeInterval) -> Double {
        guard totalDuration > 0 else { return 0 }

        let cyclePosition = elapsed.truncatingRemainder(dividingBy: totalDuration)
        let positivePosition = cyclePosition >= 0 ? cyclePosition : cyclePosition + totalDuration

        if positivePosition < inhaleDuration {
            return smoothStep(positivePosition / inhaleDuration)
        }

        let pauseEnd = inhaleDuration + pauseDuration

        if positivePosition < pauseEnd {
            return 1.0
        }

        guard exhaleDuration > 0 else { return 0 }

        let exhaleProgress = (positivePosition - pauseEnd) / exhaleDuration
        return 1.0 - smoothStep(exhaleProgress)
    }

    private func smoothStep(_ value: Double) -> Double {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }
}

@MainActor
final class BreathPhaseEngine: ObservableObject {
    @Published private(set) var breathPhase: Double = 0

    private(set) var cycle: BreathCycle
    private var cycleStartDate: Date

    init(cycle: BreathCycle = .defaultGuided, cycleStartDate: Date = Date()) {
        self.cycle = cycle
        self.cycleStartDate = cycleStartDate
#if DEBUG
        debugLogCycle("initialized")
#endif
    }

    func configure(cycle: BreathCycle, restartAt date: Date = Date()) {
        self.cycle = cycle
        cycleStartDate = date
        update(now: date)
#if DEBUG
        debugLogCycle("configured")
#endif
    }

    func reset(at date: Date = Date()) {
        cycleStartDate = date
        update(now: date)
#if DEBUG
        debugLogCycle("reset")
#endif
    }

    func update(now: Date = Date()) {
        breathPhase = cycle.breathPhase(at: now.timeIntervalSince(cycleStartDate))
    }

#if DEBUG
    private func debugLogCycle(_ event: String) {
        print(
            "BreathPhaseEngine \(event): inhale=\(cycle.inhaleDuration)s, pause=\(cycle.pauseDuration)s, exhale=\(cycle.exhaleDuration)s, total=\(cycle.totalDuration)s, phase=\(breathPhase)"
        )
    }
#endif
}
