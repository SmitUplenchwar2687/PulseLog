import Foundation

@MainActor
final class LifecycleTracker: ObservableObject {
    static let shared = LifecycleTracker()

    @Published private(set) var liveInstances: [String: Int] = [:]
    @Published private(set) var totalLiveCount = 0
    @Published private(set) var warningMessage: String?

    private init() {}

    func register(typeName: String) {
        liveInstances[typeName, default: 0] += 1
        recalculateTotals()
        AppLoggers.lifecycle.info("VM init: \(typeName, privacy: .public)")
    }

    func deregister(typeName: String) {
        let newValue = max(0, (liveInstances[typeName] ?? 1) - 1)
        if newValue == 0 {
            liveInstances.removeValue(forKey: typeName)
        } else {
            liveInstances[typeName] = newValue
        }
        recalculateTotals()
        AppLoggers.lifecycle.info("VM deinit: \(typeName, privacy: .public)")
    }

    private func recalculateTotals() {
        totalLiveCount = liveInstances.values.reduce(0, +)

        if totalLiveCount > 80 {
            warningMessage = "Live ViewModels are growing. Inspect ownership and deinit paths."
            return
        }

        if let worst = liveInstances.max(by: { $0.value < $1.value }), worst.value > 20 {
            warningMessage = "\(worst.key) has \(worst.value) live instances."
            return
        }

        warningMessage = nil
    }
}

@MainActor
class TrackedViewModel: ObservableObject {
    private let trackedTypeName: String

    init(typeName: String = String(describing: TrackedViewModel.self)) {
        trackedTypeName = typeName
        LifecycleTracker.shared.register(typeName: trackedTypeName)
    }

    deinit {
        Task { @MainActor [trackedTypeName] in
            LifecycleTracker.shared.deregister(typeName: trackedTypeName)
        }
    }
}
