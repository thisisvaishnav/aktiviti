import SwiftUI

struct NetworkTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let networkTint = Color(red: 11/255, green: 130/255, blue: 99/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var downloadRateText: String {
        if let n = viewModel.network {
            return ByteFormatter.formatRate(n.downloadRateBytesPerSec)
        }
        return "5.8 MB/s"
    }

    private var uploadRateText: String {
        if let n = viewModel.network {
            return ByteFormatter.formatRate(n.uploadRateBytesPerSec)
        }
        return "217 kB/s"
    }

    private var downloadRateNumber: String {
        if let n = viewModel.network {
            let mb = n.downloadRateBytesPerSec / (1024 * 1024)
            if mb >= 1.0 {
                return String(format: "%.1f", mb)
            } else {
                return String(format: "%.0f", n.downloadRateBytesPerSec / 1024)
            }
        }
        return "5.8"
    }

    private var downloadRateUnit: String {
        if let n = viewModel.network {
            let mb = n.downloadRateBytesPerSec / (1024 * 1024)
            return mb >= 1.0 ? "MB/s" : "kB/s"
        }
        return "MB/s"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: "Downloading",
                mainValue: downloadRateNumber,
                unit: downloadRateUnit,
                statRow1: (label: "Uploading", value: uploadRateText),
                statRow2: (label: "Today", value: "4.60 GB"),
                chartData: viewModel.networkHistory,
                chartTint: networkTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Downloading",
                    icon: "arrow.down",
                    value: downloadRateText,
                    tint: networkTint,
                    style: .progress(ratio: 0.65)
                )

                TabSubcardView(
                    title: "Uploading",
                    icon: "arrow.up",
                    value: uploadRateText,
                    tint: networkTint,
                    style: .progress(ratio: 0.22)
                )

                TabSubcardView(
                    title: "Total Today",
                    icon: "calendar",
                    value: "4.60 GB",
                    tint: networkTint,
                    style: .standard(subtitle: "Combined traffic")
                )

                TabSubcardView(
                    title: "Interface",
                    icon: "wifi",
                    value: "Connected",
                    tint: networkTint,
                    style: .topApp(
                        appName: "Wi-Fi (en0)",
                        appIcon: nil
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                metricHeader: "Network",
                items: viewModel.networkProcessRows,
                tint: networkTint
            )
        }
    }
}
