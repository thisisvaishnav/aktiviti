import SwiftUI

struct NavigationBarView: View {
    @Binding var selectedTab: NavigationTab

    var body: some View {
        HStack(spacing: 4) {
            // Space reserved for the window's native traffic lights (close, minimize, zoom)
            Spacer()
                .frame(width: 76)

            ForEach(NavigationTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 11, weight: .medium))
                        Text(tab.rawValue)
                            .font(.system(size: 12.5, weight: selectedTab == tab ? .semibold : .medium))
                    }
                    .foregroundColor(
                        selectedTab == tab ? .white : Color(red: 0.38, green: 0.38, blue: 0.42)
                    )
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(
                        selectedTab == tab ?
                        Color(red: 0.17, green: 0.45, blue: 0.98) :
                        Color.clear
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 16)
        .background(Color.white)
    }
}
