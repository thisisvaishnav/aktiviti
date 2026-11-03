import SwiftUI

struct BatteryTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let batteryTint = Color(red: 18/255, green: 136/255, blue: 74/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var percent: Int {
        Int(viewModel.battery?.percent ?? 100.0)
    }

    private var isCharging: Bool {
        viewModel.battery?.isCharging ?? true
    }

    private var powerDrawWatts: Double {
        viewModel.battery?.powerDrawWatts ?? 5.2
    }

    private var healthPercent: Int {
        Int(viewModel.battery?.healthPercent ?? 88.0)
    }

    private var cycleCount: Int {
        142
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: "Battery",
                mainValue: "\(percent)",
                unit: "%",
                statusBadge: (
                    text: isCharging ? "Power Adapter" : "On Battery",
                    isNormal: true
                ),
                statRow1: (label: "Remaining", value: isCharging ? "AC Power" : "4h 22m"),
                statRow2: (label: "Health", value: "\(healthPercent)%"),
                chartData: viewModel.batteryHistory,
                chartTint: batteryTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Power Draw",
                    icon: "bolt.fill",
                    value: String(format: "%.1f W", powerDrawWatts),
                    tint: batteryTint,
                    style: .progress(ratio: min(1.0, powerDrawWatts / 30.0))
                )

                TabSubcardView(
                    title: "Health",
                    icon: "heart.fill",
                    value: "\(healthPercent)%",
                    tint: batteryTint,
                    style: .progress(ratio: Double(healthPercent) / 100.0)
                )

                TabSubcardView(
                    title: "Cycle Count",
                    icon: "arrow.triangle.2.circlepath",
                    value: "\(cycleCount)",
                    tint: batteryTint,
                    style: .standard(subtitle: "Normal condition")
                )

                TabSubcardView(
                    title: "Top Consumer",
                    icon: "square.grid.2x2.fill",
                    value: "427 mW",
                    tint: batteryTint,
                    style: .topApp(
                        appName: viewModel.topCPUApp.name,
                        appIcon: viewModel.topCPUApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                metricHeader: "Power",
                items: viewModel.batteryProcessRows,
                tint: batteryTint
            )
        }
    }
}
