import SwiftUI
import SystemMetrics

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    private let windowBackground = Color(red: 249/255, green: 250/255, blue: 250/255)

    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar with traffic light clearance
            NavigationBarView(selectedTab: $viewModel.selectedTab)

            // Active Tab Content Area
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    switch viewModel.selectedTab {
                    case .overview:
                        OverviewTabView(viewModel: viewModel)
                    case .cpu:
                        CPUTabView(viewModel: viewModel)
                    case .memory:
                        MemoryTabView(viewModel: viewModel)
                    case .disk:
                        DiskTabView(viewModel: viewModel)
                    case .network:
                        NetworkTabView(viewModel: viewModel)
                    case .gpu:
                        GPUTabView(viewModel: viewModel)
                    case .battery:
                        BatteryTabView(viewModel: viewModel)
                    case .projects:
                        ProjectsTabView(viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 16)
            }
        }
        .background(windowBackground)
        .frame(minWidth: 1024, minHeight: 640)
    }
}
