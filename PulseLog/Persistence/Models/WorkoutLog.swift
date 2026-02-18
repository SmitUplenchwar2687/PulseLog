import Foundation
import SwiftData

@Model
final class WorkoutLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var exerciseName: String
    var type: String
    var sets: Int
    var reps: Int
    var weight: Double
    var durationMinutes: Double

    init(
        id: UUID = UUID(),
        date: Date = .now,
        exerciseName: String,
        type: String,
        sets: Int,
        reps: Int,
        weight: Double,
        durationMinutes: Double
    ) {
        self.id = id
        self.date = date
        self.exerciseName = exerciseName
        self.type = type
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.durationMinutes = durationMinutes
    }

    var volume: Double {
        Double(sets) * Double(reps) * weight
    }
}
