import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView() }
                .toolbar(.hidden, for: .tabBar)
                .tag(0)
            NavigationStack { QuestsView() }
                .toolbar(.hidden, for: .tabBar)
                .tag(1)
            NavigationStack { FriendsListView() }
                .toolbar(.hidden, for: .tabBar)
                .tag(2)
            NavigationStack { ProfileView() }
                .toolbar(.hidden, for: .tabBar)
                .tag(3)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LMTabBar(selectedTab: $selectedTab)
        }
    }
}

private struct LMTabBar: View {
    @Binding var selectedTab: Int

    private let items: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("target", "Quests"),
        ("person.2.fill", "Friends"),
        ("person.crop.circle.fill", "Profile"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Theme.ink)
                                    .frame(width: 48, height: 40)
                            }
                            Image(systemName: items[index].icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(selectedTab == index ? .white : Color(hex: "B0B0B0"))
                        }
                        Text(items[index].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(selectedTab == index ? Theme.ink : Color(hex: "B0B0B0"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
