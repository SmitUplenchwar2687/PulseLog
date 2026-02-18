import Foundation

@MainActor
final class DebugMenuState: ObservableObject {
    @Published var showLifecycleOverlay = true
}
