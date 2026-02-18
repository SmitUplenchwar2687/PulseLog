import SwiftUI
import UIKit

private final class ShakeHostingController: UIViewController {
    var onShake: (() -> Void)?

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        onShake?()
    }
}

private struct ShakeDetector: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeHostingController {
        let controller = ShakeHostingController()
        controller.onShake = onShake
        return controller
    }

    func updateUIViewController(_ uiViewController: ShakeHostingController, context: Context) {
        uiViewController.onShake = onShake
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        background(ShakeDetector(onShake: action).allowsHitTesting(false))
    }
}
