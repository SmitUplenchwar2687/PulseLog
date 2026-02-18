import SwiftUI
import SwiftData

@main
struct PulseLogApp: App {
    @StateObject private var debugMenuState = DebugMenuState()
    @State private var showMemoryDashboard = false

    private let container = PersistenceController.shared.container

    var body: some Scene {
        WindowGroup {
            AppRootView(showMemoryDashboard: $showMemoryDashboard)
                .modelContainer(container)
                .environmentObject(debugMenuState)
                .environmentObject(LifecycleTracker.shared)
                .onShake {
                    guard AppDebug.isDebugEnabled else { return }
                    showMemoryDashboard = true
                }
                .sheet(isPresented: $showMemoryDashboard) {
                    MemoryDashboardView()
                }
        }
    }
}
