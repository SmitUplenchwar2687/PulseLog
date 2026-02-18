import SwiftUI

struct WorkoutRowView: View {
    let workout: WorkoutLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(workout.exerciseName)
                    .font(.headline)
                Spacer()
                Text(workout.type)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15), in: Capsule())
            }

            Text(workout.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(workout.sets)x\(workout.reps)", systemImage: "number")
                Label(String(format: "%.1f kg", workout.weight), systemImage: "scalemass")
                Label(String(format: "%.0f min", workout.durationMinutes), systemImage: "timer")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
