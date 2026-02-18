import SwiftUI

struct AppRootView: View {
    @Binding var showMemoryDashboard: Bool
    @EnvironmentObject private var debugMenuState: DebugMenuState

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            WorkoutTrackerView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }

            ExerciseLibraryView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet.clipboard")
                }

            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            if AppDebug.isDebugEnabled {
                DebugMenuView(showMemoryDashboard: $showMemoryDashboard)
                    .tabItem {
                        Label("Debug", systemImage: "ant")
                    }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if AppDebug.isDebugEnabled && debugMenuState.showLifecycleOverlay {
                LifecycleOverlayView()
                    .padding(12)
            }
        }
    }
}
