import SwiftUI

struct NetworkTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let networkTint = Color(red: 40/255, green: 175/255, blue: 215/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var downloadRate: Double {
        viewModel.network?.downloadRateBytesPerSec ?? 0.0
    }

    private var uploadRate: Double {
        viewModel.network?.uploadRateBytesPerSec ?? 0.0
    }

    private var totalBandwidthBytesPerSec: Double {
        downloadRate + uploadRate
    }

    private var totalBandwidthText: String {
        ByteFormatter.formatBytes(UInt64(max(0, totalBandwidthBytesPerSec)), style: .memory) + "/s"
    }

    private var downloadRateText: String {
        ByteFormatter.formatBytes(UInt64(max(0, downloadRate)), style: .memory) + "/s"
    }

    private var uploadRateText: String {
        ByteFormatter.formatBytes(UInt64(max(0, uploadRate)), style: .memory) + "/s"
    }

    private var downloadedTodayText: String {
        if let net = viewModel.network {
            return ByteFormatter.formatBytes(net.totalInBytes, style: .file)
        }
        return "0 MB"
    }

    private var uploadedTodayText: String {
        if let net = viewModel.network {
            return ByteFormatter.formatBytes(net.totalOutBytes, style: .file)
        }
        return "0 MB"
    }

    private var activeInterfaceText: String {
        if let net = viewModel.network {
            return "Wi-Fi (\(net.activeInterfaceName))"
        }
        return "Wi-Fi (en0)"
    }

    private var linkSpeedText: String {
        if let net = viewModel.network {
            let band = net.wifiBandString ?? "5 GHz"
            if let speed = net.linkSpeedMbps {
                return "\(band) · \(Int(speed)) Mbps link"
            }
            return "\(band) · Connected"
        }
        return "Active link"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card: Distinct Aggregate Bandwidth
            TabHeroCardView(
                caption: "Total Bandwidth",
                mainValue: totalBandwidthText,
                unit: "",
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
                    value: downloadedTodayText,
                    tint: networkTint,
                    style: .standard(subtitle: "Inbound traffic today")
                )

                TabSubcardView(
                    title: "Uploaded Today",
                    icon: "arrow.up.circle.fill",
                    value: uploadedTodayText,
                    tint: networkTint,
                    style: .standard(subtitle: "Outbound traffic today")
                )

                TabSubcardView(
                    title: "Active Interface",
                    icon: "wifi",
                    value: activeInterfaceText,
                    tint: networkTint,
                    style: .standard(subtitle: linkSpeedText)
                )

                TabSubcardView(
                    title: "Top Network App",
                    icon: "square.grid.2x2.fill",
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
                metricHeader: "Bandwidth",
                items: viewModel.networkProcessRows,
                tint: networkTint
            )
        }
    }
}
