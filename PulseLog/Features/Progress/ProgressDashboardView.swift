import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ProgressDashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard

                    if viewModel.volumePoints.isEmpty {
                        EmptyStateView(
                            title: "No Volume Data",
                            message: "Log workouts to unlock volume trends.",
                            systemImage: "chart.line.downtrend.xyaxis"
                        )
                    } else {
                        volumeChart
                    }

                    personalRecordsSection
                }
                .padding()
            }
            .navigationTitle("Progress Dashboard")
            .task {
                viewModel.configure(context: modelContext)
            }
            .refreshable {
                await viewModel.load()
            }
            .alert("Error", isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Summary")
                .font(.headline)

            HStack {
                summaryMetric(title: "Workouts", value: "\(viewModel.weeklySummary.workoutCount)")
                summaryMetric(title: "Volume", value: String(format: "%.0f", viewModel.weeklySummary.totalVolume))
                summaryMetric(title: "Minutes", value: String(format: "%.0f", viewModel.weeklySummary.totalDuration))
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(value)
                .font(.title3.weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var volumeChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout Volume")
                .font(.headline)

            Chart(viewModel.volumePoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Volume", point.volume)
                )
                .foregroundStyle(.blue.opacity(0.15))
            }
            .frame(height: 220)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Personal Records")
                .font(.headline)

            if viewModel.personalRecords.isEmpty {
                Text("No records yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.personalRecords.prefix(10)) { record in
                    HStack {
                        Text(record.exerciseName)
                        Spacer()
                        Text(String(format: "%.1f kg x %d", record.maxWeight, record.repsAtMaxWeight))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
