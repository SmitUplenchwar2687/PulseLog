import SwiftUI

struct DebugMenuView: View {
    @Binding var showMemoryDashboard: Bool
    @EnvironmentObject private var debugMenuState: DebugMenuState
    @StateObject private var networkVM = NetworkSimulatorViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Instrumentation") {
                    Toggle("Lifecycle Overlay", isOn: $debugMenuState.showLifecycleOverlay)

                    Button("Open Memory Dashboard") {
                        showMemoryDashboard = true
                    }
                }

                Section("Network Conditions") {
                    Toggle("Enable Simulator", isOn: $networkVM.isEnabled)
                    VStack(alignment: .leading) {
                        Text("Latency: \(Int(networkVM.latencyMilliseconds)) ms")
                        Slider(value: $networkVM.latencyMilliseconds, in: 0...2500, step: 50)
                    }

                    VStack(alignment: .leading) {
                        Text("Failure Rate: \(Int(networkVM.failureRatePercentage))%")
                        Slider(value: $networkVM.failureRatePercentage, in: 0...100, step: 5)
                    }

                    Button("Apply Network Conditions") {
                        Task {
                            await networkVM.apply()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }

                Section("Debug Scenarios") {
                    NavigationLink("Memory Issue Playground") {
                        MemoryIssuePlaygroundView()
                    }

                    NavigationLink("SwiftUI Render Stressor") {
                        RenderStressorView()
                    }
                }
            }
            .navigationTitle("Debug Tools")
            .task {
                await networkVM.load()
            }
        }
    }
}
