import SwiftUI

/// Root signed-in shell: Home (dashboard) / Quests (tap-to-complete) /
/// Friends / Profile, matching the bottom nav bar in the brand mockup.
struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { QuestsView() }
                .tabItem { Label("Quests", systemImage: "target") }

            NavigationStack { FriendsListView() }
                .tabItem { Label("Friends", systemImage: "person.2.fill") }

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Theme.accentGold)
    }
}
