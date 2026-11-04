import SwiftUI
import AppKit

struct ProjectsTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let projectTint = Color(red: 43/255, green: 112/255, blue: 228/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card: Workspaces, Footprint, and Git Status
            TabHeroCardView(
                caption: "Active Workspaces",
                mainValue: viewModel.projectCountText,
                unit: "Projects",
                statusBadge: (text: "All Synced", isNormal: true),
                statRow1: (label: "Total Footprint", value: viewModel.totalProjectFootprintText),
                statRow2: (label: "Git Status", value: viewModel.isGitStatusClean ? "Clean Working Tree" : "Modified Files"),
                chartData: viewModel.cpuHistory,
                chartTint: projectTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Repositories",
                    icon: "folder.fill",
                    value: "\(viewModel.projectCountText) Repos",
                    tint: projectTint,
                    style: .standard(subtitle: "Local Git Workspaces")
                )

                TabSubcardView(
                    title: "Build Systems",
                    icon: "hammer.fill",
                    value: "Ready",
                    tint: projectTint,
                    style: .standard(subtitle: viewModel.buildSystemSummary)
                )

                TabSubcardView(
                    title: "DerivedData Cache",
                    icon: "internaldrive.fill",
                    value: viewModel.derivedDataText,
                    tint: projectTint,
                    style: .progress(ratio: viewModel.derivedDataRatio)
                )

                TabSubcardView(
                    title: "Active Project",
                    icon: "chevron.left.forwardslash.chevron.right",
                    value: viewModel.topProject.value,
                    tint: projectTint,
                    style: .topApp(
                        appName: viewModel.topProject.name,
                        appIcon: viewModel.topProject.icon
                    )
                )
            }

            // 3. Bottom Row: Process / Project Table Card
            TabProcessTableView(
                titleHeader: "Project",
                metricHeader: "Dev Footprint",
                items: viewModel.projectRows,
                tint: projectTint
            )
        }
    }
}
