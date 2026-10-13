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
            NavigationStack { LeaderboardView() }
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
        "list.number",
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
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.accent.opacity(0.15))
                                .frame(width: 48, height: 40)
                        }
                        Image(systemName: items[index])
                            .font(.system(size: 19, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundStyle(selectedTab == index
                                             ? Theme.ink
                                             : Color.gray.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 12)
    }
}