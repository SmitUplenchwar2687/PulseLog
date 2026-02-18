import SwiftUI

struct MemoryIssuePlaygroundView: View {
    @StateObject private var viewModel = MemoryIssuePlaygroundViewModel()
    @State private var useBrokenRetainCycle = true

    var body: some View {
        Form {
            Section("Retain Cycle") {
                Toggle("Broken (strong self capture)", isOn: $useBrokenRetainCycle)
                Button("Start Retain Cycle Scenario") {
                    viewModel.startRetainCycle(broken: useBrokenRetainCycle)
                }
                Button("Stop Scenario") {
                    viewModel.stopRetainCycle()
                }
                Text(viewModel.retainCycleStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Memory Growth") {
                Button("Start Unbounded Growth") {
                    viewModel.startMemoryGrowth()
                }
                Button("Stop and Clear") {
                    viewModel.stopMemoryGrowth()
                }
                Text(viewModel.growthStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Image Memory Spike") {
                Button("Decode Full-Resolution Images") {
                    viewModel.runImageSpikeScenario(useDownsampling: false)
                }
                Button("Decode Downsampled Images") {
                    viewModel.runImageSpikeScenario(useDownsampling: true)
                }
                Text(viewModel.imageStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Cache Eviction") {
                Button("Fill LRU Cache") {
                    viewModel.fillCache()
                }
                Button("Simulate Memory Warning") {
                    viewModel.simulateMemoryWarning()
                }
                Text(viewModel.cacheStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Memory Playground")
    }
}
