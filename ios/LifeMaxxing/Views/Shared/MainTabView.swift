import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @GestureState private var dragTranslation: CGFloat = 0

    private static let tabCount = 4

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width

            ZStack {
                Theme.background.ignoresSafeArea()

                // A plain HStack of all 4 tabs, offset so only one shows at a
                // time - pure SwiftUI, unlike .tabViewStyle(.page) (backed by
                // UIPageViewController, which owns its own opaque background
                // that no SwiftUI layering can see behind). Every tab stays
                // mounted (just off-screen), so nothing gets torn down and
                // re-created mid-swipe either.
                HStack(spacing: 0) {
                    NavigationStack { HomeView() }
                        .frame(width: width)
                    NavigationStack { QuestsView() }
                        .frame(width: width)
                    NavigationStack { LeaderboardView() }
                        .frame(width: width)
                    NavigationStack { ProfileView() }
                        .frame(width: width)
                }
                .offset(x: -CGFloat(selectedTab) * width + dragTranslation)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.86), value: selectedTab)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .updating($dragTranslation) { value, state, _ in
                            // Ignore drags that are more vertical than horizontal,
                            // so this doesn't fight each tab's own vertical scrolling.
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            var translation = value.translation.width
                            // Rubber-band resistance past the first/last tab.
                            if selectedTab == 0 && translation > 0 { translation /= 3 }
                            if selectedTab == Self.tabCount - 1 && translation < 0 { translation /= 3 }
                            state = translation
                        }
                        .onEnded { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            let threshold = width * 0.22
                            if value.translation.width < -threshold, selectedTab < Self.tabCount - 1 {
                                selectedTab += 1
                            } else if value.translation.width > threshold, selectedTab > 0 {
                                selectedTab -= 1
                            }
                        }
                )
            }
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
                    // No withAnimation here - MainTabView's own
                    // .animation(value: selectedTab) drives this, so tapping
                    // and swiping produce the same slide motion.
                    selectedTab = index
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