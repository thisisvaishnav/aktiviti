import SwiftUI

struct BatteryTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let batteryTint = Color(red: 45/255, green: 185/255, blue: 85/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var batteryLevel: Double {
        viewModel.battery?.percent ?? 100.0
    }

    private var isCharging: Bool {
        viewModel.battery?.isCharging ?? false
    }

    private var isPluggedIn: Bool {
        viewModel.battery?.isPluggedIn ?? true
    }

    private var systemPowerDrawWatts: Double {
        viewModel.battery?.powerDrawWatts ?? 0.0
    }

    private var healthPercent: Int {
        Int(viewModel.battery?.healthPercent ?? 100.0)
    }

    private var cycleCount: Int {
        viewModel.battery?.cycleCount ?? 0
    }

    private var powerStateText: String {
        if isCharging {
            return "Charging"
        } else if isPluggedIn {
            return "AC Power"
        } else {
            return "On Battery"
        }
    }

    private var powerSourceText: String {
        if let name = viewModel.battery?.adapterName, !name.isEmpty {
            return name
        }
        if let w = viewModel.battery?.adapterWatts, w > 0 {
            return "\(w)W Power Adapter"
        }
        return isPluggedIn ? "AC Adapter" : "Internal Battery"
    }

    private var powerSourceSubtitle: String {
        if isPluggedIn {
            return isCharging ? "Charging Active" : "Connected · Power Maintained"
        }
        return "Discharging"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card: Battery Level, Power State & Real-time Draw in Watts
            TabHeroCardView(
                caption: "Battery Level",
                mainValue: String(format: "%.0f", batteryLevel),
                unit: "%",
                statusBadge: (text: isCharging ? "Charging" : (isPluggedIn ? "AC Connected" : "Battery"), isNormal: true),
                statRow1: (label: "Power State", value: powerStateText),
                statRow2: (label: "System Draw", value: String(format: "%.1f W", systemPowerDrawWatts)),
                chartData: viewModel.batteryHistory,
                chartTint: batteryTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Power Source",
                    icon: "powerplug.fill",
                    value: powerSourceText,
                    tint: batteryTint,
                    style: .standard(subtitle: powerSourceSubtitle)
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
                    icon: "square.grid.2x2.fill",
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
                metricHeader: "Power Impact",
                items: viewModel.batteryProcessRows,
                tint: batteryTint
            )
        }
    }
}
