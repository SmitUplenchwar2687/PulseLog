import Foundation

struct StressWorkoutEntry: Identifiable {
    let id: Int
    let title: String
    let sets: Int
    let reps: Int
}

@MainActor
final class RenderRowViewModel: ObservableObject, Identifiable {
    let id: Int
    let title: String
    let detail: String

    init(entry: StressWorkoutEntry) {
        id = entry.id
        title = entry.title
        detail = "\(entry.sets)x\(entry.reps)"
    }
}

@MainActor
final class RenderStressorViewModel: TrackedViewModel {
    let entries: [StressWorkoutEntry]
    let fixedRowViewModels: [RenderRowViewModel]

    @Published private(set) var brokenVMInitCount = 0

    init() {
        let entries = (1...500).map { index in
            StressWorkoutEntry(
                id: index,
                title: "Workout \(index)",
                sets: Int.random(in: 2...6),
                reps: Int.random(in: 4...15)
            )
        }
        self.entries = entries
        self.fixedRowViewModels = entries.map(RenderRowViewModel.init)

        super.init(typeName: String(describing: RenderStressorViewModel.self))
    }

    func makeBrokenViewModel(for entry: StressWorkoutEntry) -> RenderRowViewModel {
        brokenVMInitCount += 1
        return RenderRowViewModel(entry: entry)
    }

    func resetBrokenCounter() {
        brokenVMInitCount = 0
    }
}
