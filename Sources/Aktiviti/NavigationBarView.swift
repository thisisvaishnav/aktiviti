import SwiftUI

struct NavigationBarView: View {
    @Binding var selectedTab: NavigationTab

    var body: some View {
        HStack(spacing: 0) {
            // Space reserved for the window's native traffic lights (close, minimize, zoom)
            Spacer()
                .frame(width: 76)

            // Pill Strip Container
            HStack(spacing: 2) {
                ForEach(NavigationTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 11, weight: .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundStyle(
                            isSelected ? activeTextColor(for: tab) : Color(red: 100/255, green: 100/255, blue: 108/255)
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            isSelected ? activePillColor(for: tab) : Color.clear
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("Tab_\(tab.rawValue)")
                    .accessibilityLabel(tab.rawValue)
                }
            }
            .padding(3)
            .background(Color(red: 242/255, green: 242/255, blue: 245/255))
            .clipShape(Capsule())

            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.horizontal, 16)
        .background(Color(red: 249/255, green: 250/255, blue: 250/255))
    }

    private func activeTextColor(for tab: NavigationTab) -> Color {
        switch tab {
        case .overview:
            return Color(red: 43/255, green: 112/255, blue: 228/255)
        case .cpu:
            return Color(red: 43/255, green: 112/255, blue: 228/255)
        case .memory:
            return Color(red: 110/255, green: 57/255, blue: 230/255)
        case .disk:
            return Color(red: 217/255, green: 119/255, blue: 6/255)
        case .network:
            return Color(red: 11/255, green: 130/255, blue: 99/255)
        case .gpu:
            return Color(red: 217/255, green: 35/255, blue: 117/255)
        case .battery:
            return Color(red: 18/255, green: 136/255, blue: 74/255)
        case .projects:
            return Color(red: 99/255, green: 102/255, blue: 241/255)
        }
    }

    private func activePillColor(for tab: NavigationTab) -> Color {
        switch tab {
        case .overview:
            return Color(red: 211/255, green: 220/255, blue: 239/255)
        case .cpu:
            return Color(red: 211/255, green: 220/255, blue: 239/255)
        case .memory:
            return Color(red: 214/255, green: 211/255, blue: 231/255)
        case .disk:
            return Color(red: 254/255, green: 236/255, blue: 212/255)
        case .network:
            return Color(red: 209/255, green: 240/255, blue: 232/255)
        case .gpu:
            return Color(red: 252/255, green: 218/255, blue: 233/255)
        case .battery:
            return Color(red: 216/255, green: 243/255, blue: 228/255)
        case .projects:
            return Color(red: 224/255, green: 231/255, blue: 255/255)
        }
    }
}
