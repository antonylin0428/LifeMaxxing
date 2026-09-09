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

    private let items: [String] = [
        "house.fill",
        "target",
        "person.2.fill",
        "person.crop.circle.fill",
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedTab = index
                    }
                } label: {
                    ZStack {
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white)
                                .frame(width: 52, height: 44)
                        }
                        Image(systemName: items[index])
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(selectedTab == index
                                             ? Color(hex: "1A1A1A")
                                             : .white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color(hex: "1A1A1A"))
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal, 48)
        .padding(.bottom, 12)
    }
}