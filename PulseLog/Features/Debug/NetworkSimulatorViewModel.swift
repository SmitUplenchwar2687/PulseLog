import Foundation

@MainActor
final class NetworkSimulatorViewModel: TrackedViewModel {
    @Published var isEnabled = false
    @Published var latencyMilliseconds: Double = 0
    @Published var failureRatePercentage: Double = 0

    private let simulator: NetworkConditionSimulator

    init(simulator: NetworkConditionSimulator = .shared) {
        self.simulator = simulator
        super.init(typeName: String(describing: NetworkSimulatorViewModel.self))
    }

    func load() async {
        let snapshot = await simulator.snapshot()
        isEnabled = snapshot.enabled
        latencyMilliseconds = Double(snapshot.latencyMilliseconds)
        failureRatePercentage = snapshot.failureRate * 100
    }

    func apply() async {
        await simulator.configure(
            enabled: isEnabled,
            latencyMilliseconds: UInt64(latencyMilliseconds),
            failureRate: failureRatePercentage / 100
        )
    }
}
