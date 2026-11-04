import SwiftUI

struct DiskTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let diskTint = Color(red: 235/255, green: 130/255, blue: 60/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var availableGB: Double {
        if let d = viewModel.disk {
            return Double(d.availableBytes) / (1024 * 1024 * 1024)
        }
        return 0.0
    }

    private var usedGB: Double {
        if let d = viewModel.disk {
            return Double(d.usedBytes) / (1024 * 1024 * 1024)
        }
        return 0.0
    }

    private var usedRatio: Double {
        if let d = viewModel.disk, d.totalBytes > 0 {
            return Double(d.usedBytes) / Double(d.totalBytes)
        }
        return 0.0
    }

    private var writtenTodayGBText: String {
        if let d = viewModel.disk {
            return ByteFormatter.formatBytes(d.writtenTodayBytes, style: .file)
        }
        return "0 GB"
    }

    private var readSpeedText: String {
        if let d = viewModel.disk {
            return ByteFormatter.formatBytes(UInt64(max(0, d.readRateBytesPerSec)), style: .memory) + "/s"
        }
        return "0 kB/s"
    }

    private var writeSpeedText: String {
        if let d = viewModel.disk {
            return ByteFormatter.formatBytes(UInt64(max(0, d.writeRateBytesPerSec)), style: .memory) + "/s"
        }
        return "0 kB/s"
    }

    private var volumeFormatText: String {
        viewModel.disk?.volumeFormat ?? "APFS"
    }

    private var volumeNameText: String {
        viewModel.disk?.volumeName ?? "Macintosh HD"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card: Available Storage & I/O Speeds
            TabHeroCardView(
                caption: "Available Storage",
                mainValue: String(format: "%.1f", availableGB),
                unit: "GB Free",
                statusBadge: (text: "/ \(volumeNameText)", isNormal: true),
                statRow1: (label: "Read Speed", value: readSpeedText),
                statRow2: (label: "Write Speed", value: writeSpeedText),
                chartData: viewModel.diskHistory,
                chartTint: diskTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards (Non-repeating disk usage parameters)
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Used Space",
                    icon: "internaldrive.fill",
                    value: String(format: "%.1f GB", usedGB),
                    tint: diskTint,
                    style: .progress(ratio: usedRatio)
                )

                TabSubcardView(
                    title: "Written Today",
                    icon: "arrow.down.doc.fill",
                    value: writtenTodayGBText,
                    tint: diskTint,
                    style: .standard(subtitle: "Cumulative SSD writes")
                )

                TabSubcardView(
                    title: "Volume Format",
                    icon: "lock.shield.fill",
                    value: volumeFormatText,
                    tint: diskTint,
                    style: .standard(subtitle: "Encrypted & Trimmed")
                )

                TabSubcardView(
                    title: "Top Disk App",
                    icon: "square.grid.2x2.fill",
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
                metricHeader: "Disk I/O",
                items: viewModel.diskProcessRows,
                tint: diskTint
            )
        }
    }
}
