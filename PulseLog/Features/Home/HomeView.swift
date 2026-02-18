import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    weeklySummaryCard

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Workouts")
                            .font(.headline)

                        if viewModel.recentWorkouts.isEmpty {
                            Text("No workouts logged yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.recentWorkouts) { workout in
                                WorkoutRowView(workout: workout)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("PulseLog")
            .task {
                viewModel.configure(context: modelContext)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack {
                metricView(value: "\(viewModel.weeklySummary.workoutCount)", title: "Sessions")
                metricView(value: String(format: "%.0f", viewModel.weeklySummary.totalVolume), title: "Volume")
                metricView(value: String(format: "%.0f min", viewModel.weeklySummary.totalDuration), title: "Duration")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.18), Color.mint.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private func metricView(value: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
