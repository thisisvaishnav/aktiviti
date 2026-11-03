import SwiftUI

struct GPUTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let gpuTint = Color(red: 217/255, green: 35/255, blue: 117/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var gpuUtil: Double {
        viewModel.gpu?.utilization ?? 78.0
    }

    private var modelName: String {
        viewModel.gpu?.deviceName ?? "Apple M2"
    }

    private var memAllocText: String {
        if let g = viewModel.gpu {
            return ByteFormatter.formatBytes(g.allocatedMemoryBytes, style: .memory)
        }
        return "0.50 GB"
    }

    private var avgUtilText: String {
        if let g = viewModel.gpu {
            return String(format: "%.0f%%", g.averageUtilization)
        }
        return "4%"
    }

    private var peakUtilText: String {
        if let g = viewModel.gpu {
            return String(format: "%.0f%%", g.peakUtilization)
        }
        return "18%"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: modelName,
                mainValue: String(format: "%.0f", gpuUtil),
                unit: "%",
                statRow1: (label: "Average", value: avgUtilText),
                statRow2: (label: "Peak", value: peakUtilText),
                chartData: viewModel.gpuHistory,
                chartTint: gpuTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "Utilization",
                    icon: "square.stack.3d.up.fill",
                    value: String(format: "%.0f%%", gpuUtil),
                    tint: gpuTint,
                    style: .progress(ratio: gpuUtil / 100.0)
                )

                TabSubcardView(
                    title: "Allocated RAM",
                    icon: "memorychip.fill",
                    value: memAllocText,
                    tint: gpuTint,
                    style: .progress(ratio: 0.28)
                )

                TabSubcardView(
                    title: "Engine",
                    icon: "cpu.fill",
                    value: "Apple Silicon",
                    tint: gpuTint,
                    style: .standard(subtitle: "Metal 3 Hardware Accel")
                )

                TabSubcardView(
                    title: "Top App",
                    icon: "square.grid.2x2.fill",
                    value: "54.0%",
                    tint: gpuTint,
                    style: .topApp(
                        appName: viewModel.topCPUApp.name,
                        appIcon: viewModel.topCPUApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                metricHeader: "GPU",
                items: viewModel.gpuProcessRows,
                tint: gpuTint
            )
        }
    }
}
