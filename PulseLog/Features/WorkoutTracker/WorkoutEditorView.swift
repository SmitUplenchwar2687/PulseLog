import SwiftUI

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input = WorkoutInput()

    let onSave: (WorkoutInput) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Exercise name", text: $input.exerciseName)
                    Picker("Type", selection: $input.type) {
                        Text("Strength").tag("Strength")
                        Text("Cardio").tag("Cardio")
                        Text("Mobility").tag("Mobility")
                        Text("Sports").tag("Sports")
                    }
                }

                Section("Performance") {
                    Stepper("Sets: \(input.sets)", value: $input.sets, in: 1...20)
                    Stepper("Reps: \(input.reps)", value: $input.reps, in: 1...50)
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("0", value: $input.weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Duration (min)")
                        Spacer()
                        TextField("0", value: $input.durationMinutes, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    DatePicker("Date", selection: $input.date)
                }
            }
            .navigationTitle("Log Workout")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(input)
                        dismiss()
                    }
                    .disabled(input.exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
