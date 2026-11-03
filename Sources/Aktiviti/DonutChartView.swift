import SwiftUI

struct DonutSlice: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
}

struct DonutChartView: View {
    let slices: [DonutSlice]
    let centerPrimaryText: String
    let centerSecondaryText: String
    var ringSize: CGFloat = 104
    var strokeWidth: CGFloat = 16

    var body: some View {
        let total = slices.reduce(0.0) { $0 + $1.value }
        let safeTotal = total > 0 ? total : 1.0

        ZStack {
            // Background track
            Circle()
                .stroke(Color(red: 0.94, green: 0.95, blue: 0.97), lineWidth: strokeWidth)
                .frame(width: ringSize, height: ringSize)

            // Segmented slices
            ForEach(0..<slices.count, id: \.self) { index in
                let (startFraction, endFraction) = computeFractions(for: index, safeTotal: safeTotal)
                Circle()
                    .trim(from: CGFloat(startFraction), to: CGFloat(endFraction))
                    .stroke(
                        slices[index].color,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: ringSize, height: ringSize)
            }

            // Center labels
            VStack(spacing: 1) {
                Text(centerPrimaryText)
                    .font(.system(size: centerPrimaryText.count > 6 ? 16 : 19, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.08, green: 0.12, blue: 0.20))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text(centerSecondaryText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.62))
            }
        }
        .frame(width: ringSize, height: ringSize)
    }

    private func computeFractions(for index: Int, safeTotal: Double) -> (Double, Double) {
        var start = 0.0
        for i in 0..<index {
            start += slices[i].value / safeTotal
        }
        let end = start + (slices[index].value / safeTotal)
        // Leave a microscopic gap between segments for clean visual separation
        let gap = slices.count > 1 ? 0.004 : 0.0
        return (start + (gap / 2.0), max(start, end - (gap / 2.0)))
    }
}
