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
        viewModel.gpu?.deviceName ?? "Apple M2 GPU"
    }

    private var memAllocText: String {
        if let g = viewModel.gpu {
            return ByteFormatter.formatBytes(g.allocatedMemoryBytes, style: .memory)
        }
        return "1.40 GB"
    }

    private var avgUtilText: String {
        if let g = viewModel.gpu {
            return String(format: "%.0f%%", g.averageUtilization)
        }
        return "14%"
    }

    private var peakUtilText: String {
        if let g = viewModel.gpu {
            return String(format: "%.0f%%", g.peakUtilization)
        }
        return "48%"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card
            TabHeroCardView(
                caption: modelName,
                mainValue: String(format: "%.0f", gpuUtil),
                unit: "%",
                statusBadge: (text: "10 GPU Cores", isNormal: true),
                statRow1: (label: "Allocated VRAM", value: memAllocText),
                statRow2: (label: "Peak Today", value: peakUtilText),
                chartData: viewModel.gpuHistory,
                chartTint: gpuTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "GPU Load",
                    icon: "square.stack.3d.up.fill",
                    value: String(format: "%.0f%%", gpuUtil),
                    tint: gpuTint,
                    style: .progress(ratio: gpuUtil / 100.0)
                )

                TabSubcardView(
                    title: "VRAM Footprint",
                    icon: "memorychip.fill",
                    value: memAllocText,
                    tint: gpuTint,
                    style: .standard(subtitle: "Unified memory pool")
                )

                TabSubcardView(
                    title: "Metal Engine",
                    icon: "cpu.fill",
                    value: "Metal 3",
                    tint: gpuTint,
                    style: .standard(subtitle: "Hardware Acceleration")
                )

                TabSubcardView(
                    title: "Top GPU App",
                    icon: "square.grid.2x2.fill",
                    value: viewModel.topGPUApp.value,
                    tint: gpuTint,
                    style: .topApp(
                        appName: viewModel.topGPUApp.name,
                        appIcon: viewModel.topGPUApp.icon
                    )
                )
            }

            // 3. Bottom Row: Process Table Card
            TabProcessTableView(
                titleHeader: "App",
                metricHeader: "GPU Load",
                items: viewModel.gpuProcessRows,
                tint: gpuTint
            )
        }
    }
}
