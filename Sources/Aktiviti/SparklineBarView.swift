import SwiftUI

struct SparklineBarView: View {
    let values: [Double] // Normalized 0.0 - 1.0
    let tintColor: Color

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let maxHeight = proxy.size.height
            let count = max(values.count, 1)
            let itemSpacing: CGFloat = 2.5
            let totalSpacing = CGFloat(count - 1) * itemSpacing
            let barWidth = max(2.5, min((totalWidth - totalSpacing) / CGFloat(count), 6.5))

            HStack(alignment: .bottom, spacing: itemSpacing) {
                ForEach(0..<values.count, id: \.self) { i in
                    let val = CGFloat(min(max(values[i], 0.06), 1.0))
                    let barHeight = max(3.5, val * maxHeight)

                    Capsule()
                        .fill(tintColor.opacity(0.85))
                        .frame(width: barWidth, height: barHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .bottomLeading)
        }
        .frame(height: 32)
    }
}
