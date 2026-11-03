import SwiftUI

struct DiskTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let diskTint = Color(red: 217/255, green: 119/255, blue: 6/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var totalDiskGB: Double {
        Double(viewModel.disk?.totalBytes ?? (245 * 1024 * 1024 * 1024)) / (1024 * 1024 * 1024)
    }

    private var freeDiskGB: Double {
        Double(viewModel.disk?.availableBytes ?? (87 * 1024 * 1024 * 1024)) / (1024 * 1024 * 1024)
    }

    private var readRateText: String {
        if let d = viewModel.disk {
            return ByteFormatter.formatRate(d.readRateBytesPerSec)
        }
        return "17.6 MB/s"
    }

    private var writeRateText: String {
        if let d = viewModel.disk {
            return ByteFormatter.formatRate(d.writeRateBytesPerSec)
        }
        return "5.2 MB/s"
    }

    private var writtenTodayText: String {
        if let d = viewModel.disk, d.writtenTodayBytes > 0 {
            return ByteFormatter.formatBytes(d.writtenTodayBytes, style: .file)
        }
        return "39.5 GB"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: String(format: "Free of %.2f GB", totalDiskGB),
                mainValue: String(format: "%.2f", freeDiskGB),
                unit: "GB",
                statusBadge: (text: "Healthy", isNormal: true),
                statRow1: (label: "Reading", value: readRateText),
                statRow2: (label: "Writing", value: writeRateText),
                chartData: viewModel.diskHistory,
                chartTint: diskTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Reading",
                    icon: "arrow.down.circle.fill",
                    value: readRateText,
                    tint: diskTint,
                    style: .progress(ratio: 0.35)
                )

                TabSubcardView(
                    title: "Writing",
                    icon: "arrow.up.circle.fill",
                    value: writeRateText,
                    tint: diskTint,
                    style: .progress(ratio: 0.15)
                )

                TabSubcardView(
                    title: "Written Today",
                    icon: "clock.fill",
                    value: writtenTodayText,
                    tint: diskTint,
                    style: .standard(subtitle: "Cumulative I/O")
                )

                TabSubcardView(
                    title: "Primary Disk",
                    icon: "internaldrive.fill",
                    value: "APFS Encrypted",
                    tint: diskTint,
                    style: .topApp(
                        appName: "Macintosh HD",
                        appIcon: NSWorkspace.shared.icon(for: .volume)
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                metricHeader: "Disk I/O",
                items: viewModel.diskProcessRows,
                tint: diskTint
            )
        }
    }
}
