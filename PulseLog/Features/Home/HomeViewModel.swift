import Foundation
import SwiftData

@MainActor
final class HomeViewModel: TrackedViewModel {
    @Published private(set) var weeklySummary = WeeklySummary(workoutCount: 0, totalVolume: 0, totalDuration: 0)
    @Published private(set) var recentWorkouts: [WorkoutLog] = []

    private var repository: WorkoutRepository?

    init() {
        super.init(typeName: String(describing: HomeViewModel.self))
    }

    func configure(context: ModelContext) {
        guard repository == nil else { return }
        repository = WorkoutRepository(context: context)

        Task {
            await refresh()
        }
    }

    func refresh() async {
        guard let repository else { return }

        do {
            let workouts = try repository.fetchAllWorkouts()
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
            let weekWorkouts = workouts.filter { $0.date >= weekAgo }

            weeklySummary = WeeklySummary(
                workoutCount: weekWorkouts.count,
                totalVolume: weekWorkouts.reduce(0) { $0 + $1.volume },
                totalDuration: weekWorkouts.reduce(0) { $0 + $1.durationMinutes }
            )

            recentWorkouts = Array(workouts.prefix(5))
        } catch {
            AppLoggers.persistence.error("Home summary load failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
