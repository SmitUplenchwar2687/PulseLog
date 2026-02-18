import SwiftUI

struct MemoryDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MemoryDashboardViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Live Memory")
                    .font(.title2.bold())

                HStack {
                    metricCard(title: "Physical Footprint", value: String(format: "%.1f MB", viewModel.footprintMB))
                    metricCard(title: "Resident Size", value: String(format: "%.1f MB", viewModel.residentMB))
                    metricCard(title: "Peak Resident", value: String(format: "%.1f MB", viewModel.peakResidentMB))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 60s")
                        .font(.headline)
                    SparklineView(values: viewModel.sparklineValues, lineColor: warningUIColor)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                warningLegend

                Spacer()

                HStack {
                    Button("Export CSV") {
                        viewModel.exportCSV()
                    }
                    .buttonStyle(.borderedProminent)

                    if let url = viewModel.exportURL {
                        ShareLink(item: url) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .navigationTitle("Memory Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var warningUIColor: Color {
        switch viewModel.warningColor {
        case "red":
            return .red
        case "yellow":
            return .yellow
        default:
            return .green
        }
    }

    private var warningLegend: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Thresholds")
                .font(.headline)
            Text("Yellow: 150 MB+")
                .foregroundStyle(.yellow)
            Text("Red: 250 MB+")
                .foregroundStyle(.red)
        }
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
