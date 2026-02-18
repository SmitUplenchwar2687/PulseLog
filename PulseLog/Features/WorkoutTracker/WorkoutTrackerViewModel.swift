import Foundation
import SwiftData

struct WorkoutInput {
    var exerciseName: String = ""
    var type: String = "Strength"
    var sets: Int = 3
    var reps: Int = 10
    var weight: Double = 20
    var durationMinutes: Double = 30
    var date: Date = .now
}

@MainActor
final class WorkoutTrackerViewModel: TrackedViewModel {
    @Published private(set) var workouts: [WorkoutLog] = []
    @Published private(set) var isLoading = false
    @Published private(set) var canLoadMore = true
    @Published var selectedType = "All"
    @Published var useDateFilter = false
    @Published var startDate = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @Published var endDate = .now
    @Published var errorMessage: String?

    let pageSize = 20
    let workoutTypes = ["All", "Strength", "Cardio", "Mobility", "Sports"]

    private var currentPage = 0
    private var repository: WorkoutRepository?

    init() {
        super.init(typeName: String(describing: WorkoutTrackerViewModel.self))
    }

    func configure(context: ModelContext) {
        guard repository == nil else { return }
        repository = WorkoutRepository(context: context)
        Task {
            await refresh()
        }
    }

    func refresh() async {
        currentPage = 0
        workouts.removeAll()
        canLoadMore = true
        await loadNextPage(resetError: true)
    }

    func loadNextPage(resetError: Bool = false) async {
        guard !isLoading, canLoadMore else { return }
        guard let repository else { return }

        isLoading = true
        if resetError { errorMessage = nil }

        do {
            let next = try repository.fetchWorkouts(page: currentPage, pageSize: pageSize, filter: currentFilter)
            workouts.append(contentsOf: next)
            canLoadMore = next.count == pageSize
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func applyFilter() async {
        await refresh()
    }

    func createWorkout(from input: WorkoutInput) async {
        guard let repository else { return }

        do {
            try repository.createWorkout(
                exerciseName: input.exerciseName,
                type: input.type,
                sets: input.sets,
                reps: input.reps,
                weight: input.weight,
                durationMinutes: input.durationMinutes,
                date: input.date
            )
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteWorkout(_ workout: WorkoutLog) async {
        guard let repository else { return }

        do {
            try repository.deleteWorkout(workout)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var currentFilter: WorkoutFilter {
        WorkoutFilter(
            startDate: useDateFilter ? startDate : nil,
            endDate: useDateFilter ? endDate : nil,
            type: selectedType == "All" ? nil : selectedType
        )
    }
}
