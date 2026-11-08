import SwiftUI
import AppKit
import SystemMetrics

enum ProjectsSubtab: String, CaseIterable, Identifiable {
    case workspaces = "Workspaces"
    case ports = "Port Doctor"

    var id: String { rawValue }
}

struct ProjectsTabView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var selectedSubtab: ProjectsSubtab = .workspaces

    private let projectTint = Color(red: 43/255, green: 112/255, blue: 228/255)
    private let cardBackground = Color(red: 242/255, green: 242/255, blue: 245/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 12) {
            // Mode Selector Bar
            HStack {
                Picker("", selection: $selectedSubtab) {
                    ForEach(ProjectsSubtab.allCases) { sub in
                        Text(sub.rawValue).tag(sub)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)

                Spacer()

                if selectedSubtab == .ports {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.orphanedPortCount > 0 ? Color.orange : Color.green)
                            .frame(width: 7, height: 7)
                        Text("\(viewModel.listeningPorts.count) Ports Active")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                    }
                } else {
                    Text("\(viewModel.projectCountText) Active Git Workspaces")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                }
            }
            .padding(.horizontal, 4)

            if selectedSubtab == .workspaces {
                workspacesView
            } else {
                portDoctorView
            }
        }
    }

    // MARK: - Workspaces View

    @ViewBuilder
    private var workspacesView: some View {
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

    // MARK: - Port Doctor View

    @ViewBuilder
    private var portDoctorView: some View {
        // 1. Hero Card for Ports
        TabHeroCardView(
            caption: "Dev Servers & Open Ports",
            mainValue: "\(viewModel.listeningPorts.count)",
            unit: "Open Ports",
            statusBadge: viewModel.orphanedPortCount > 0
                ? (text: "\(viewModel.orphanedPortCount) Zombie", isNormal: false)
                : (text: "All Healthy", isNormal: true),
            statRow1: (label: "Dev Servers", value: "\(viewModel.devPortCount) Active"),
            statRow2: (label: "Reclaimable", value: viewModel.orphanedPortCount > 0 ? "\(viewModel.orphanedPortCount) Idle" : "None"),
            chartData: viewModel.cpuHistory,
            chartTint: Color(red: 235/255, green: 94/255, blue: 40/255),
            chartMax: 100.0
        )

        // 2. Middle Row: 4 Subcards for Port Doctor
        HStack(spacing: 14) {
            TabSubcardView(
                title: "Dev Servers",
                icon: "network",
                value: "\(viewModel.devPortCount) Running",
                tint: Color(red: 235/255, green: 94/255, blue: 40/255),
                style: .standard(subtitle: "Local Web & API Servers")
            )

            TabSubcardView(
                title: "Port Reclaimer",
                icon: "bolt.shield.fill",
                value: "Active",
                tint: Color(red: 235/255, green: 94/255, blue: 40/255),
                style: .standard(subtitle: "1-Click Zombie Free")
            )

            TabSubcardView(
                title: "Localhost Only",
                icon: "lock.shield.fill",
                value: "\(viewModel.listeningPorts.filter { $0.isLocalhostOnly }.count) Bound",
                tint: Color(red: 235/255, green: 94/255, blue: 40/255),
                style: .standard(subtitle: "Loopback Interface")
            )

            TabSubcardView(
                title: "Active Listener",
                icon: "dot.radiowaves.left.and.right",
                value: viewModel.topListeningApp.value,
                tint: Color(red: 235/255, green: 94/255, blue: 40/255),
                style: .topApp(
                    appName: viewModel.topListeningApp.name,
                    appIcon: viewModel.topListeningApp.icon
                )
            )
        }

        // 3. Port Doctor Table Card
        portDoctorTableCard
    }

    private var portDoctorTableCard: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack {
                Text("Port & Dev Server")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                Spacer()
                Text("Action")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .overlay(Color(red: 232/255, green: 232/255, blue: 236/255))
                .padding(.horizontal, 14)

            // Rows
            if viewModel.listeningPorts.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(red: 161/255, green: 161/255, blue: 170/255))
                    Text("No active listening ports detected")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 11) {
                    ForEach(viewModel.listeningPorts.prefix(5)) { item in
                        HStack(spacing: 12) {
                            // Port Badge
                            HStack(spacing: 3) {
                                Text(":\(item.port)")
                                    .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color(red: 235/255, green: 94/255, blue: 40/255))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 254/255, green: 237/255, blue: 230/255))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            // Details
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(item.processName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 24/255))

                                    Text(item.serviceName)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Color(red: 113/255, green: 113/255, blue: 122/255))

                                    if item.isOrphaned {
                                        Text("Zombie")
                                            .font(.system(size: 9.5, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Color(red: 254/255, green: 226/255, blue: 226/255))
                                            .foregroundStyle(Color(red: 220/255, green: 38/255, blue: 38/255))
                                            .clipShape(Capsule())
                                    }
                                }

                                Text(item.workingDirectory != nil ? "PID \(item.pid) · \(item.workingDirectory!)" : "PID \(item.pid) · \(ByteFormatter.formatBytes(item.memoryBytes, style: .memory)) RAM")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Color(red: 142/255, green: 142/255, blue: 147/255))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }

                            Spacer()

                            // Reclaim / Kill Button
                            Button(action: {
                                withAnimation {
                                    viewModel.reclaimPort(port: item.port)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Reclaim")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4.5)
                                .background(Color(red: 254/255, green: 242/255, blue: 242/255))
                                .foregroundStyle(Color(red: 220/255, green: 38/255, blue: 38/255))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
