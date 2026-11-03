import SwiftUI

struct ProjectsTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let projectTint = Color(red: 43/255, green: 112/255, blue: 228/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: "Active Workspaces",
                mainValue: "3",
                unit: "Projects",
                statusBadge: (text: "Clean", isNormal: true),
                statRow1: (label: "Dev Footprint", value: "1.42 GB"),
                statRow2: (label: "Git Status", value: "Up to Date"),
                chartData: viewModel.cpuHistory,
                chartTint: projectTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Active Repo",
                    icon: "folder.fill",
                    value: "aktiviti",
                    tint: projectTint,
                    style: .standard(subtitle: "Swift 5.9 / macOS 14+")
                )

                TabSubcardView(
                    title: "Compilers",
                    icon: "hammer.fill",
                    value: "Idle",
                    tint: projectTint,
                    style: .standard(subtitle: "swift-frontend")
                )

                TabSubcardView(
                    title: "Memory",
                    icon: "memorychip.fill",
                    value: "1.42 GB",
                    tint: projectTint,
                    style: .progress(ratio: 0.18)
                )

                TabSubcardView(
                    title: "Primary Editor",
                    icon: "chevron.left.forwardslash.chevron.right",
                    value: "Xcode",
                    tint: projectTint,
                    style: .topApp(
                        appName: "Xcode",
                        appIcon: NSWorkspace.shared.icon(for: .application)
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                metricHeader: "Dev Impact",
                items: viewModel.cpuProcessRows,
                tint: projectTint
            )
        }
    }
}
