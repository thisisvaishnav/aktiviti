import SwiftUI

struct CPUTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let cpuTint = Color(red: 43/255, green: 112/255, blue: 228/255)
    private let badgeBg = Color(red: 220/255, green: 231/255, blue: 253/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var currentUsage: Double {
        viewModel.cpu?.totalUsage ?? 23.0
    }

    private var userUsage: Double {
        viewModel.cpu?.userUsage ?? 16.0
    }

    private var systemUsage: Double {
        viewModel.cpu?.systemUsage ?? 7.0
    }

    private var coreTopology: (total: Int, p: Int, e: Int) {
        if let top = viewModel.cpu?.topology {
            return (top.totalCores, top.performanceCores, top.efficiencyCores)
        }
        return (12, 8, 4)
    }

    private var loadAvgString: String {
        if let cpu = viewModel.cpu {
            return String(format: "%.2f", cpu.loadAverages.0)
        }
        return "2.51"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: "Now",
                mainValue: String(format: "%.0f", currentUsage),
                unit: "%",
                statRow1: (label: "Average today", value: "40%"),
                statRow2: (label: "Load", value: loadAvgString),
                chartData: viewModel.cpuHistory,
                chartTint: cpuTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "User",
                    icon: "asterisk",
                    value: String(format: "%.0f%%", userUsage > 0 ? userUsage : 16.0),
                    tint: cpuTint,
                    style: .standard(subtitle: "Your apps")
                )

                TabSubcardView(
                    title: "System",
                    icon: "gearshape.fill",
                    value: String(format: "%.0f%%", systemUsage > 0 ? systemUsage : 7.0),
                    tint: cpuTint,
                    style: .standard(subtitle: "macOS")
                )

                TabSubcardView(
                    title: "Cores",
                    icon: "bolt.fill",
                    value: "\(coreTopology.total)",
                    tint: cpuTint,
                    style: .badges(badges: [
                        (text: "\(coreTopology.p) P", bg: badgeBg, fg: cpuTint),
                        (text: "\(coreTopology.e) E", bg: badgeBg, fg: cpuTint)
                    ])
                )

                TabSubcardView(
                    title: "Top App",
                    icon: "square.grid.2x2.fill",
                    value: viewModel.topCPUApp.value,
                    tint: cpuTint,
                    style: .topApp(
                        appName: viewModel.topCPUApp.name,
                        appIcon: viewModel.topCPUApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                metricHeader: "CPU",
                items: viewModel.cpuProcessRows,
                tint: cpuTint
            )
        }
    }
}
