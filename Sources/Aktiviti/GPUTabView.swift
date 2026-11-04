import SwiftUI

struct GPUTabView: View {
    @Bindable var viewModel: DashboardViewModel

    private let gpuTint = Color(red: 175/255, green: 70/255, blue: 235/255)

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    private var deviceName: String {
        viewModel.gpu?.deviceName ?? "Apple Silicon GPU"
    }

    private var currentUtil: Double {
        viewModel.gpu?.utilization ?? 0.0
    }

    private var coreCountBadgeText: String {
        if let g = viewModel.gpu, g.coreCount > 0 {
            return "\(g.coreCount) GPU Cores"
        }
        return "GPU Active"
    }

    private var inUseVRAMText: String {
        if let g = viewModel.gpu, g.inUseMemoryBytes > 0 {
            return ByteFormatter.formatBytes(g.inUseMemoryBytes, style: .memory)
        }
        return "0 MB"
    }

    private var allocatedVRAMText: String {
        if let g = viewModel.gpu, g.allocatedMemoryBytes > 0 {
            return ByteFormatter.formatBytes(g.allocatedMemoryBytes, style: .memory)
        }
        return "0 MB"
    }

    private var peakUtilText: String {
        if let g = viewModel.gpu {
            return String(format: "%.0f%%", g.peakUtilization)
        }
        return "0%"
    }

    private var avgUtilText: String {
        if let g = viewModel.gpu {
            return String(format: "%.0f%%", g.averageUtilization)
        }
        return "0%"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 1. Hero Card: Device Name, Utilization, Core Count, VRAM
            TabHeroCardView(
                caption: deviceName,
                mainValue: String(format: "%.0f", currentUtil),
                unit: "%",
                statusBadge: (text: coreCountBadgeText, isNormal: true),
                statRow1: (label: "Allocated VRAM", value: allocatedVRAMText),
                statRow2: (label: "Peak Today", value: peakUtilText),
                chartData: viewModel.gpuHistory,
                chartTint: gpuTint,
                chartMax: 100.0
            )

            // 2. Middle Row: 4 Subcards
            HStack(spacing: 14) {
                TabSubcardView(
                    title: "GPU Load",
                    icon: "speedometer",
                    value: String(format: "%.0f%%", currentUtil),
                    tint: gpuTint,
                    style: .progress(ratio: currentUtil / 100.0)
                )

                TabSubcardView(
                    title: "VRAM Footprint",
                    icon: "memorychip.fill",
                    value: inUseVRAMText,
                    tint: gpuTint,
                    style: .standard(subtitle: "Unified memory pool")
                )

                TabSubcardView(
                    title: "Metal Engine",
                    icon: "cube.transparent.fill",
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
                metricHeader: "GPU Load",
                items: viewModel.gpuProcessRows,
                tint: gpuTint
            )
        }
    }
}
