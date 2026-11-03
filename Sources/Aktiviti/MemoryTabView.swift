import SwiftUI

struct MemoryTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let memoryTint = Color(red: 110/255, green: 57/255, blue: 230/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var totalBytes: UInt64 {
        viewModel.ram?.totalBytes ?? (64 * 1024 * 1024 * 1024)
    }

    private var totalGBText: String {
        let gb = Double(totalBytes) / (1024 * 1024 * 1024)
        return "\(Int(round(gb))) GB"
    }

    private var usedGBText: String {
        if let r = viewModel.ram {
            let usedGB = Double(r.usedBytes) / (1024 * 1024 * 1024)
            return String(format: "%.2f", usedGB)
        }
        return "52.56"
    }

    private var freeGBText: String {
        if let r = viewModel.ram {
            let freeGB = Double(r.freeBytes) / (1024 * 1024 * 1024)
            return String(format: "%.2f GB", freeGB)
        }
        return "11.44 GB"
    }

    private var swapText: String {
        if let r = viewModel.ram, r.swapUsedBytes > 0 {
            return ByteFormatter.formatBytes(r.swapUsedBytes, style: .memory)
        }
        return "0 MB"
    }

    private var appGBText: String {
        if let r = viewModel.ram, r.appBytes > 0 {
            return ByteFormatter.formatBytes(r.appBytes, style: .memory)
        }
        return "23.32 GB"
    }

    private var wiredGBText: String {
        if let r = viewModel.ram, r.wiredBytes > 0 {
            return ByteFormatter.formatBytes(r.wiredBytes, style: .memory)
        }
        return "5.37 GB"
    }

    private var compressedGBText: String {
        if let r = viewModel.ram, r.compressedBytes > 0 {
            return ByteFormatter.formatBytes(r.compressedBytes, style: .memory)
        }
        return "23.87 GB"
    }

    private var appRatio: Double {
        if let r = viewModel.ram, r.totalBytes > 0 {
            return Double(r.appBytes) / Double(r.totalBytes)
        }
        return 0.36
    }

    private var wiredRatio: Double {
        if let r = viewModel.ram, r.totalBytes > 0 {
            return Double(r.wiredBytes) / Double(r.totalBytes)
        }
        return 0.08
    }

    private var compressedRatio: Double {
        if let r = viewModel.ram, r.totalBytes > 0 {
            return Double(r.compressedBytes) / Double(r.totalBytes)
        }
        return 0.37
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: "In use of \(totalGBText)",
                mainValue: usedGBText,
                unit: "GB",
                statusBadge: (text: "Normal", isNormal: true),
                statRow1: (label: "Free", value: freeGBText),
                statRow2: (label: "Swap", value: swapText),
                chartData: viewModel.memoryHistory,
                chartTint: memoryTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "App",
                    icon: "square.grid.2x2.fill",
                    value: appGBText,
                    tint: memoryTint,
                    style: .progress(ratio: appRatio)
                )

                TabSubcardView(
                    title: "Wired",
                    icon: "lock.fill",
                    value: wiredGBText,
                    tint: memoryTint,
                    style: .progress(ratio: wiredRatio)
                )

                TabSubcardView(
                    title: "Compressed",
                    icon: "archivebox.fill",
                    value: compressedGBText,
                    tint: memoryTint,
                    style: .progress(ratio: compressedRatio)
                )

                TabSubcardView(
                    title: "Top App",
                    icon: "square.grid.2x2.fill",
                    value: viewModel.topMemoryApp.value,
                    tint: memoryTint,
                    style: .topApp(
                        appName: viewModel.topMemoryApp.name,
                        appIcon: viewModel.topMemoryApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                metricHeader: "Memory",
                items: viewModel.memoryProcessRows,
                tint: memoryTint
            )
        }
    }
}
