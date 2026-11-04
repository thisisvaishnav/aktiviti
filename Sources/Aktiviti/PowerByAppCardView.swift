import AppKit
import SwiftUI

struct PowerByAppCardView: View {
    let processes: [ProcessDisplayItem]

    private let segmentColors: [Color] = [
        Color(red: 0.07, green: 0.53, blue: 0.29), // Emerald
        Color(red: 0.12, green: 0.68, blue: 0.38), // Green
        Color(red: 0.02, green: 0.60, blue: 0.85), // Teal
        Color(red: 0.85, green: 0.47, blue: 0.03), // Orange
        Color(red: 0.80, green: 0.82, blue: 0.88)  // Gray for other
    ]

    private let defaultPowers: [Double] = [427.0, 367.0, 145.0, 86.0]
    private let otherPower: Double = 650.0

    private var top4: [ProcessDisplayItem] {
        Array(processes.prefix(4))
    }

    private var totalPowerW: Double {
        let totalPowerMW = defaultPowers.reduce(0.0, +) + otherPower
        return totalPowerMW / 1000.0
    }

    private var slices: [DonutSlice] {
        var result: [DonutSlice] = []
        for (idx, _) in top4.enumerated() {
            let p = idx < defaultPowers.count ? defaultPowers[idx] : 50.0
            let col = idx < segmentColors.count ? segmentColors[idx] : segmentColors[0]
            result.append(DonutSlice(value: p, color: col))
        }
        if result.isEmpty {
            for (idx, p) in defaultPowers.enumerated() {
                result.append(DonutSlice(value: p, color: segmentColors[idx]))
            }
        }
        result.append(DonutSlice(value: otherPower, color: segmentColors[4]))
        return result
    }

    var body: some View {
        MetricCardContainer {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.86, green: 0.97, blue: 0.90))
                        .frame(width: 24, height: 24)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.07, green: 0.53, blue: 0.29))
                }
                Text("Power by App")
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
                    centerPrimaryText: String(format: "%.1f W", totalPowerW),
                    centerSecondaryText: "all apps",
                    ringSize: 98,
                    strokeWidth: 14
                )

                // Top Apps List
                VStack(spacing: 5) {
                    ForEach(Array(top4.enumerated()), id: \.element.id) { index, proc in
                        let powerVal = index < defaultPowers.count ? defaultPowers[index] : 45.0
                        appRow(
                            icon: proc.icon,
                            name: proc.name,
                            dotColor: segmentColors[index % segmentColors.count],
                            value: ByteFormatter.formatMilliwatts(powerVal)
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

                        Text(ByteFormatter.formatMilliwatts(otherPower))
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
