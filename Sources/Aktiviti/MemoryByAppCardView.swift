import AppKit
import SwiftUI

struct MemoryByAppCardView: View {
    let processes: [ProcessDisplayItem]

    private let segmentColors: [Color] = [
        Color(red: 0.43, green: 0.22, blue: 0.90), // Purple
        Color(red: 0.17, green: 0.44, blue: 0.89), // Blue
        Color(red: 0.02, green: 0.60, blue: 0.85), // Cyan
        Color(red: 0.85, green: 0.47, blue: 0.03), // Orange
        Color(red: 0.80, green: 0.82, blue: 0.88)  // Gray for other
    ]

    private var top4: [ProcessDisplayItem] {
        Array(processes.prefix(4))
    }

    private var safeTotalBytes: UInt64 {
        let total = processes.reduce(UInt64(0)) { $0 + $1.bytes }
        return max(total, 63_618_973_696)
    }

    private var otherBytes: UInt64 {
        let top4Total = top4.reduce(UInt64(0)) { $0 + $1.bytes }
        return safeTotalBytes > top4Total ? (safeTotalBytes - top4Total) : (safeTotalBytes / 3)
    }

    private var totalGB: Double {
        Double(safeTotalBytes) / 1_073_741_824.0
    }

    private var slices: [DonutSlice] {
        var result: [DonutSlice] = []
        for (idx, proc) in top4.enumerated() {
            let color = idx < segmentColors.count ? segmentColors[idx] : segmentColors[0]
            result.append(DonutSlice(value: Double(proc.bytes), color: color))
        }
        result.append(DonutSlice(value: Double(otherBytes), color: segmentColors[4]))
        return result
    }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.93, green: 0.91, blue: 0.99))
                        .frame(width: 24, height: 24)
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.43, green: 0.22, blue: 0.90))
                }
                Text("Memory by App")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            HStack(spacing: 16) {
                // Donut Chart
                DonutChartView(
                    slices: slices,
                    centerPrimaryText: String(format: "%.2f GB", totalGB),
                    centerSecondaryText: "all apps",
                    ringSize: 98,
                    strokeWidth: 14
                )

                // Top Apps List
                VStack(spacing: 5) {
                    ForEach(Array(top4.enumerated()), id: \.element.id) { index, proc in
                        appRow(
                            icon: proc.icon,
                            name: proc.name,
                            dotColor: segmentColors[index % segmentColors.count],
                            value: ByteFormatter.formatMemory(proc.bytes)
                        )
                    }

                    // Other entry
                    HStack(spacing: 6) {
                        Circle()
                            .fill(segmentColors[4])
                            .frame(width: 6, height: 6)

                        ZStack {
                            Circle()
                                .fill(Color(red: 0.90, green: 0.92, blue: 0.96))
                                .frame(width: 16, height: 16)
                            Image(systemName: "ellipsis")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color(red: 0.45, green: 0.52, blue: 0.62))
                        }

                        Text("Other")
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.40))

                        Spacer()

                        Text(ByteFormatter.formatMemory(otherBytes))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
    }

    private func appRow(icon: NSImage, name: String, dotColor: Color, value: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))

            Text(name)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.18))
                .lineLimit(1)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
        }
    }
}
