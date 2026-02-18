import SwiftUI

struct LifecycleOverlayView: View {
    @EnvironmentObject private var tracker: LifecycleTracker

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VMs: \(tracker.totalLiveCount)")
                .font(.caption.bold())

            ForEach(tracker.liveInstances.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                Text("\(key): \(value)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let warning = tracker.warningMessage {
                Text(warning)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(maxWidth: 220, alignment: .trailing)
    }
}
