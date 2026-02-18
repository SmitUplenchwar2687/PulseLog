import Foundation
import Darwin

struct MemorySample: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let physicalFootprint: UInt64
    let residentSize: UInt64
    let peakResidentSize: UInt64
}

@MainActor
final class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()

    @Published private(set) var samples: [MemorySample] = []
    @Published private(set) var latest: MemorySample?

    private var pollingTask: Task<Void, Never>?

    private init() {}

    func start() {
        guard pollingTask == nil else { return }

        pollingTask = Task {
            while !Task.isCancelled {
                if let sample = sampleMemory() {
                    latest = sample
                    samples.append(sample)
                    if samples.count > 60 {
                        samples.removeFirst(samples.count - 60)
                    }
                }

                // 1 second cadence keeps overhead small while still exposing memory trends.
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func exportCSV() throws -> URL {
        let header = "timestamp,physical_footprint,resident_size,peak_resident_size\n"
        let body = samples.map { sample in
            "\(sample.timestamp.timeIntervalSince1970),\(sample.physicalFootprint),\(sample.residentSize),\(sample.peakResidentSize)"
        }.joined(separator: "\n")

        let csv = header + body
        let filename = "pulselog-memory-\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func sampleMemory() -> MemorySample? {
        var basicInfo = mach_task_basic_info()
        var basicCount = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<natural_t>.size)

        let basicResult = withUnsafeMutablePointer(to: &basicInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(basicCount)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &basicCount
                )
            }
        }

        guard basicResult == KERN_SUCCESS else { return nil }

        var vmInfo = task_vm_info_data_t()
        var vmCount = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)

        let vmResult = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_VM_INFO),
                    $0,
                    &vmCount
                )
            }
        }

        guard vmResult == KERN_SUCCESS else { return nil }

        return MemorySample(
            timestamp: Date(),
            physicalFootprint: vmInfo.phys_footprint,
            residentSize: basicInfo.resident_size,
            peakResidentSize: basicInfo.resident_size_max
        )
    }
}
