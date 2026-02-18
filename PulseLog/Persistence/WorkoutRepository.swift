import Foundation
import SwiftData

struct WorkoutFilter: Equatable {
    var startDate: Date?
    var endDate: Date?
    var type: String?

    static let all = WorkoutFilter(startDate: nil, endDate: nil, type: nil)
}

@MainActor
final class WorkoutRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createWorkout(
        exerciseName: String,
        type: String,
        sets: Int,
        reps: Int,
        weight: Double,
        durationMinutes: Double,
        date: Date
    ) throws {
        let workout = WorkoutLog(
            date: date,
            exerciseName: exerciseName,
            type: type,
            sets: sets,
            reps: reps,
            weight: weight,
            durationMinutes: durationMinutes
        )
        context.insert(workout)
        try context.save()
    }

    func deleteWorkout(_ workout: WorkoutLog) throws {
        context.delete(workout)
        try context.save()
    }

    func fetchWorkouts(page: Int, pageSize: Int, filter: WorkoutFilter) throws -> [WorkoutLog] {
        let interval = SignpostInterval(name: "SwiftDataFetch", message: "workouts page=\(page)")
        defer { interval.end(message: "completed") }

        var descriptor = FetchDescriptor<WorkoutLog>(
            sortBy: [SortDescriptor(\WorkoutLog.date, order: .reverse)]
        )
        descriptor.fetchLimit = pageSize
        descriptor.fetchOffset = max(0, page * pageSize)

        descriptor.predicate = makePredicate(filter: filter)

        let workouts = try context.fetch(descriptor)
        AppLoggers.persistence.debug("Fetched \(workouts.count, privacy: .public) workouts")
        return workouts
    }

    func fetchAllWorkouts(filter: WorkoutFilter = .all) throws -> [WorkoutLog] {
        let interval = SignpostInterval(name: "SwiftDataFetch", message: "workouts all")
        defer { interval.end(message: "completed") }

        var descriptor = FetchDescriptor<WorkoutLog>(
            sortBy: [SortDescriptor(\WorkoutLog.date, order: .reverse)]
        )
        descriptor.predicate = makePredicate(filter: filter)
        return try context.fetch(descriptor)
    }

    private func makePredicate(filter: WorkoutFilter) -> Predicate<WorkoutLog>? {
        let startDate = filter.startDate
        let endDate = filter.endDate
        let type = filter.type?.trimmingCharacters(in: .whitespacesAndNewlines)

        if startDate == nil, endDate == nil, type == nil || type?.isEmpty == true {
            return nil
        }

        if let startDate, let endDate, let type, !type.isEmpty {
            return #Predicate<WorkoutLog> { workout in
                workout.date >= startDate && workout.date <= endDate && workout.type == type
            }
        }

        if let startDate, let endDate {
            return #Predicate<WorkoutLog> { workout in
                workout.date >= startDate && workout.date <= endDate
            }
        }

        if let startDate, let type, !type.isEmpty {
            return #Predicate<WorkoutLog> { workout in
                workout.date >= startDate && workout.type == type
            }
        }

        if let endDate, let type, !type.isEmpty {
            return #Predicate<WorkoutLog> { workout in
                workout.date <= endDate && workout.type == type
            }
        }

        if let startDate {
            return #Predicate<WorkoutLog> { workout in
                workout.date >= startDate
            }
        }

        if let endDate {
            return #Predicate<WorkoutLog> { workout in
                workout.date <= endDate
            }
        }

        if let type, !type.isEmpty {
            return #Predicate<WorkoutLog> { workout in
                workout.type == type
            }
        }

        return nil
    }
}
