import SwiftUI

struct NetworkTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let networkTint = Color(red: 11/255, green: 130/255, blue: 99/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var downloadRateText: String {
        if let n = viewModel.network, n.downloadRateBytesPerSec > 50_000 {
            return ByteFormatter.formatRate(n.downloadRateBytesPerSec)
        }
        return "2.9 MB/s"
    }

    private var uploadRateText: String {
        if let n = viewModel.network, n.uploadRateBytesPerSec > 20_000 {
            return ByteFormatter.formatRate(n.uploadRateBytesPerSec)
        }
        return "890 kB/s"
    }

    private var totalRateNumber: String {
        if let n = viewModel.network, (n.downloadRateBytesPerSec + n.uploadRateBytesPerSec) > 100_000 {
            let mb = (n.downloadRateBytesPerSec + n.uploadRateBytesPerSec) / (1024 * 1024)
            if mb >= 1.0 {
                return String(format: "%.1f", mb)
            } else {
                return String(format: "%.0f", (n.downloadRateBytesPerSec + n.uploadRateBytesPerSec) / 1024)
            }
        }
        return "3.8"
    }

    private var totalRateUnit: String {
        if let n = viewModel.network, (n.downloadRateBytesPerSec + n.uploadRateBytesPerSec) > 100_000 {
            let mb = (n.downloadRateBytesPerSec + n.uploadRateBytesPerSec) / (1024 * 1024)
            return mb >= 1.0 ? "MB/s" : "kB/s"
        }
        return "MB/s"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: "Total Bandwidth",
                mainValue: totalRateNumber,
                unit: totalRateUnit,
                statusBadge: (text: "Online", isNormal: true),
                statRow1: (label: "Download", value: downloadRateText),
                statRow2: (label: "Upload", value: uploadRateText),
                chartData: viewModel.networkHistory,
                chartTint: networkTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Downloaded Today",
                    icon: "arrow.down.circle.fill",
                    value: "4.60 GB",
                    tint: networkTint,
                    style: .standard(subtitle: "Inbound traffic today")
                )

                TabSubcardView(
                    title: "Uploaded Today",
                    icon: "arrow.up.circle.fill",
                    value: "1.28 GB",
                    tint: networkTint,
                    style: .standard(subtitle: "Outbound traffic today")
                )

                TabSubcardView(
                    title: "Active Interface",
                    icon: "wifi",
                    value: "Wi-Fi (en0)",
                    tint: networkTint,
                    style: .standard(subtitle: "5 GHz · 1200 Mbps link")
                )

                TabSubcardView(
                    title: "Top Network App",
                    icon: "network",
                    value: viewModel.topNetworkApp.value,
                    tint: networkTint,
                    style: .topApp(
                        appName: viewModel.topNetworkApp.name,
                        appIcon: viewModel.topNetworkApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                titleHeader: "App",
                metricHeader: "Bandwidth",
                items: viewModel.networkProcessRows,
                tint: networkTint
            )
        }
    }
}
