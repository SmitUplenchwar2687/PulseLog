import Foundation

@MainActor
final class MemoryDashboardViewModel: TrackedViewModel {
    @Published private(set) var samples: [MemorySample] = []
    @Published private(set) var latest: MemorySample?
    @Published var exportURL: URL?

    private let monitor: MemoryMonitor
    private var syncTask: Task<Void, Never>?

    init(monitor: MemoryMonitor = .shared) {
        self.monitor = monitor
        super.init(typeName: String(describing: MemoryDashboardViewModel.self))
    }

    func start() {
        monitor.start()

        syncTask = Task {
            while !Task.isCancelled {
                samples = monitor.samples
                latest = monitor.latest
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    func stop() {
        syncTask?.cancel()
        syncTask = nil
        monitor.stop()
    }

    var footprintMB: Double {
        Double(latest?.physicalFootprint ?? 0) / (1024 * 1024)
    }

    var residentMB: Double {
        Double(latest?.residentSize ?? 0) / (1024 * 1024)
    }

    var peakResidentMB: Double {
        Double(latest?.peakResidentSize ?? 0) / (1024 * 1024)
    }

    var warningColor: String {
        if footprintMB >= 250 { return "red" }
        if footprintMB >= 150 { return "yellow" }
        return "green"
    }

    var sparklineValues: [Double] {
        samples.map { Double($0.physicalFootprint) / (1024 * 1024) }
    }

    func exportCSV() {
        do {
            exportURL = try monitor.exportCSV()
        } catch {
            AppLoggers.memory.error("CSV export failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
