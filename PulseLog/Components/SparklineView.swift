import SwiftUI

struct SparklineView: View {
    let values: [Double]
    var lineColor: Color = .blue

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard values.count > 1 else { return }

                let minValue = values.min() ?? 0
                let maxValue = values.max() ?? 1
                let range = max(maxValue - minValue, 0.0001)

                for (index, value) in values.enumerated() {
                    let x = geometry.size.width * CGFloat(index) / CGFloat(values.count - 1)
                    let normalizedY = (value - minValue) / range
                    let y = geometry.size.height * (1 - CGFloat(normalizedY))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 50)
    }
}
