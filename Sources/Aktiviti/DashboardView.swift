import SwiftUI
import SystemMetrics

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar with traffic light spacing
            NavigationBarView(selectedTab: $viewModel.selectedTab)

            // Content Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Top 6 Metric Cards (3 columns x 2 rows)
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        OverviewCPUCard(cpu: viewModel.cpu, history: viewModel.cpuHistory)
                        OverviewMemoryCard(ram: viewModel.ram, history: viewModel.memoryHistory)
                        OverviewGPUCard(gpu: viewModel.gpu, history: viewModel.gpuHistory)

                        OverviewDiskCard(disk: viewModel.disk, history: viewModel.diskHistory)
                        OverviewNetworkCard(network: viewModel.network, history: viewModel.networkHistory)
                        OverviewBatteryCard(battery: viewModel.battery, history: viewModel.batteryHistory)
                    }

                    // Bottom 3 Detailed Analytics Cards (3 columns x 1 row)
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        MemoryByTypeCardView(ram: viewModel.ram)
                        MemoryByAppCardView(processes: viewModel.displayProcesses)
                        PowerByAppCardView(processes: viewModel.powerProcesses.isEmpty ? viewModel.displayProcesses : viewModel.powerProcesses)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .background(Color.white)
        .frame(minWidth: 1024, minHeight: 640)
    }
}
