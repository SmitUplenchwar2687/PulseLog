import Foundation
import SwiftData

struct VolumePoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}

struct PersonalRecord: Identifiable {
    var id: String { exerciseName }
    let exerciseName: String
    let maxWeight: Double
    let repsAtMaxWeight: Int
}

struct WeeklySummary {
    let workoutCount: Int
    let totalVolume: Double
    let totalDuration: Double
}

@MainActor
final class ProgressDashboardViewModel: TrackedViewModel {
    @Published private(set) var volumePoints: [VolumePoint] = []
    @Published private(set) var personalRecords: [PersonalRecord] = []
    @Published private(set) var weeklySummary = WeeklySummary(workoutCount: 0, totalVolume: 0, totalDuration: 0)
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var repository: WorkoutRepository?

    init() {
        super.init(typeName: String(describing: ProgressDashboardViewModel.self))
    }

    func configure(context: ModelContext) {
        guard repository == nil else { return }
        repository = WorkoutRepository(context: context)

        Task {
            await load()
        }
    }

    func load() async {
        guard let repository else { return }
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let workouts = try repository.fetchAllWorkouts()
            buildVolumeSeries(workouts: workouts)
            buildPersonalRecords(workouts: workouts)
            buildWeeklySummary(workouts: workouts)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func buildVolumeSeries(workouts: [WorkoutLog]) {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            calendar.startOfDay(for: workout.date)
        }

        volumePoints = grouped
            .map { day, logs in
                VolumePoint(date: day, volume: logs.reduce(0) { $0 + $1.volume })
            }
            .sorted { $0.date < $1.date }
    }

    private func buildPersonalRecords(workouts: [WorkoutLog]) {
        let grouped = Dictionary(grouping: workouts, by: { $0.exerciseName })

        personalRecords = grouped.compactMap { exerciseName, logs in
            guard let record = logs.max(by: { $0.weight < $1.weight }) else { return nil }
            return PersonalRecord(
                exerciseName: exerciseName,
                maxWeight: record.weight,
                repsAtMaxWeight: record.reps
            )
        }
        .sorted { $0.exerciseName.localizedCaseInsensitiveCompare($1.exerciseName) == .orderedAscending }
    }

    private func buildWeeklySummary(workouts: [WorkoutLog]) {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        let recent = workouts.filter { $0.date >= weekAgo }

        weeklySummary = WeeklySummary(
            workoutCount: recent.count,
            totalVolume: recent.reduce(0) { $0 + $1.volume },
            totalDuration: recent.reduce(0) { $0 + $1.durationMinutes }
        )
    }
}
