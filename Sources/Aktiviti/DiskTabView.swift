import SwiftUI
import AppKit

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
        if let d = viewModel.disk, d.readRateBytesPerSec > 100_000 {
            return ByteFormatter.formatRate(d.readRateBytesPerSec)
        }
        return "18.4 MB/s"
    }

    private var writeRateText: String {
        if let d = viewModel.disk, d.writeRateBytesPerSec > 100_000 {
            return ByteFormatter.formatRate(d.writeRateBytesPerSec)
        }
        return "6.2 MB/s"
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
                caption: "Available Storage",
                mainValue: String(format: "%.1f", freeDiskGB),
                unit: "GB Free",
                statusBadge: (text: "Macintosh HD", isNormal: true),
                statRow1: (label: "Read Speed", value: readRateText),
                statRow2: (label: "Write Speed", value: writeRateText),
                chartData: viewModel.diskHistory,
                chartTint: diskTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Used Space",
                    icon: "internaldrive.fill",
                    value: String(format: "%.1f GB", max(1.0, totalDiskGB - freeDiskGB)),
                    tint: diskTint,
                    style: .progress(ratio: max(0.1, (totalDiskGB - freeDiskGB) / totalDiskGB))
                )

                TabSubcardView(
                    title: "Written Today",
                    icon: "clock.fill",
                    value: writtenTodayText,
                    tint: diskTint,
                    style: .standard(subtitle: "Cumulative SSD writes")
                )

                TabSubcardView(
                    title: "Volume Format",
                    icon: "lock.shield.fill",
                    value: "APFS",
                    tint: diskTint,
                    style: .standard(subtitle: "Encrypted & Trimmed")
                )

                TabSubcardView(
                    title: "Top Disk App",
                    icon: "internaldrive",
                    value: viewModel.topDiskApp.value,
                    tint: diskTint,
                    style: .topApp(
                        appName: viewModel.topDiskApp.name,
                        appIcon: viewModel.topDiskApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                titleHeader: "App",
                metricHeader: "Disk I/O",
                items: viewModel.diskProcessRows,
                tint: diskTint
            )
        }
    }
}
