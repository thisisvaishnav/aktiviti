import SwiftUI
import SystemMetrics

struct MemoryByTypeCardView: View {
    let ram: RAMMetrics?

    var body: some View {
        MetricCardContainer {
            // Header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(red: 0.93, green: 0.91, blue: 0.99))
                        .frame(width: 24, height: 24)
                    Image(systemName: "memorychip")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.43, green: 0.22, blue: 0.90))
                }
                Text("Memory by Type")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            }

            let appGB = Double(ram?.appBytes ?? 23_783_448_576) / 1_073_741_824.0
            let wiredGB = Double(ram?.wiredBytes ?? 6_088_294_400) / 1_073_741_824.0
            let compGB = Double(ram?.compressedBytes ?? 26_349_953_024) / 1_073_741_824.0
            let cachedGB = Double(ram?.cachedBytes ?? 11_081_056_256) / 1_073_741_824.0
            let freeGB = Double(ram?.freeBytes ?? 1_417_723_904) / 1_073_741_824.0
            let usedPct = ram?.usedPercent ?? 82.0

            let slices: [DonutSlice] = [
                DonutSlice(value: max(appGB, 1.0), color: Color(red: 0.17, green: 0.44, blue: 0.89)),
                DonutSlice(value: max(wiredGB, 1.0), color: Color(red: 0.85, green: 0.47, blue: 0.03)),
                DonutSlice(value: max(compGB, 1.0), color: Color(red: 0.07, green: 0.53, blue: 0.29)),
                DonutSlice(value: max(cachedGB, 1.0), color: Color(red: 0.02, green: 0.60, blue: 0.85)),
                DonutSlice(value: max(freeGB, 1.0), color: Color(red: 0.80, green: 0.82, blue: 0.88))
            ]

            HStack(spacing: 16) {
                // Donut Chart
                DonutChartView(
                    slices: slices,
                    centerPrimaryText: String(format: "%.0f%%", usedPct > 0 ? usedPct : 82.0),
                    centerSecondaryText: "in use",
                    ringSize: 98,
                    strokeWidth: 14
                )

                // Legend List
                VStack(spacing: 5) {
                    legendRow(title: "App", dotColor: Color(red: 0.17, green: 0.44, blue: 0.89), value: String(format: "%.2f GB", appGB))
                    legendRow(title: "Wired", dotColor: Color(red: 0.85, green: 0.47, blue: 0.03), value: String(format: "%.2f GB", wiredGB))
                    legendRow(title: "Compressed", dotColor: Color(red: 0.07, green: 0.53, blue: 0.29), value: String(format: "%.2f GB", compGB))
                    legendRow(title: "Cached", dotColor: Color(red: 0.02, green: 0.60, blue: 0.85), value: String(format: "%.2f GB", cachedGB))
                    legendRow(title: "Free", dotColor: Color(red: 0.80, green: 0.82, blue: 0.88), value: String(format: "%.2f GB", freeGB))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
    }

    private func legendRow(title: String, dotColor: Color, value: String) -> some View {
        HStack {
            Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            Text(title)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.40))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.10, green: 0.10, blue: 0.12))
        }
    }
}
