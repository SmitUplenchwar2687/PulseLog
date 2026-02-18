import Foundation

actor NetworkConditionSimulator {
    struct Snapshot: Sendable {
        var enabled: Bool
        var latencyMilliseconds: UInt64
        var failureRate: Double
    }

    static let shared = NetworkConditionSimulator()

    private var snapshotValue = Snapshot(enabled: false, latencyMilliseconds: 0, failureRate: 0)

    func configure(enabled: Bool, latencyMilliseconds: UInt64, failureRate: Double) {
        snapshotValue.enabled = enabled
        snapshotValue.latencyMilliseconds = latencyMilliseconds
        snapshotValue.failureRate = max(0, min(1, failureRate))
    }

    func snapshot() -> Snapshot {
        snapshotValue
    }

    func applySimulationIfNeeded() async throws {
        let settings = snapshotValue
        guard settings.enabled else { return }

        if settings.latencyMilliseconds > 0 {
            try? await Task.sleep(nanoseconds: settings.latencyMilliseconds * 1_000_000)
        }

        if Double.random(in: 0...1) < settings.failureRate {
            throw NetworkError.simulatedFailure
        }
    }
}
