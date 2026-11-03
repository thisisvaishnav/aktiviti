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
        viewModel.battery?.isCharging ?? false
    }

    private var isPluggedIn: Bool {
        viewModel.battery?.isPluggedIn ?? true
    }

    private var powerDrawWatts: Double {
        viewModel.battery?.powerDrawWatts ?? 12.8
    }

    private var healthPercent: Int {
        Int(viewModel.battery?.healthPercent ?? 98.0)
    }

    private var cycleCount: Int {
        142
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: "Battery Level",
                mainValue: "\(percent)",
                unit: "%",
                statusBadge: (
                    text: isCharging ? "Charging" : (isPluggedIn ? "Fully Charged" : "On Battery"),
                    isNormal: true
                ),
                statRow1: (label: "Power State", value: isPluggedIn ? "AC Power" : "Discharging"),
                statRow2: (label: "System Draw", value: String(format: "%.1f W", powerDrawWatts)),
                chartData: viewModel.batteryHistory,
                chartTint: batteryTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Power Source",
                    icon: "powerplug.fill",
                    value: isPluggedIn ? "AC Adapter" : "Battery",
                    tint: batteryTint,
                    style: .standard(subtitle: isPluggedIn ? "MagSafe 3 Connected" : "Internal Battery")
                )

                TabSubcardView(
                    title: "Battery Health",
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
                    icon: "bolt.fill",
                    value: viewModel.topBatteryApp.value,
                    tint: batteryTint,
                    style: .topApp(
                        appName: viewModel.topBatteryApp.name,
                        appIcon: viewModel.topBatteryApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                titleHeader: "App",
                metricHeader: "Power Impact",
                items: viewModel.batteryProcessRows,
                tint: batteryTint
            )
        }
    }
}
