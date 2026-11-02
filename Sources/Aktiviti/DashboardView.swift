import SwiftUI
import SystemMetrics

struct DashboardView: View {
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                StorageCardView(disk: viewModel.disk)
                MemoryCardView(ram: viewModel.ram)
                CPUCardView(cpu: viewModel.cpu)
            }
            .padding([.top, .horizontal], 16)

            ProcessListView(
                processes: viewModel.displayProcesses,
                isLoading: viewModel.isLoading
            )
        }
        .frame(minWidth: 480, minHeight: 640)
    }
}
