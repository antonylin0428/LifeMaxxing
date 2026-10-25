import SwiftUI

struct FriendsListView: View {
    @State private var viewModel = FriendsViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                if viewModel.isLoading && viewModel.friends.isEmpty {
                    FriendsListSkeletonView()
                } else {
                    VStack(spacing: 20) {
                        if !viewModel.received.isEmpty {
                            pendingSection
                        }
                        friendsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .refreshable { await viewModel.load() }
        }
        .navigationTitle("Friends")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: ShowAddFriend()) {
                    Image(systemName: "person.badge.plus")
                        .font(Theme.font(17, .regular))
                }
            }
        }
        .task { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Pending Requests")
            VStack(spacing: 8) {
                ForEach(viewModel.received) { request in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color(hex: "FFE07A").opacity(0.6))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(request.requesterUsername.prefix(1)).uppercased())
                                    .font(Theme.font(18))
                                    .foregroundStyle(Theme.ink)
                            )

                        Text(request.requesterUsername)
                            .font(Theme.font(16, .regular))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Button("Accept") {
                            Task { await viewModel.accept(request) }
                        }
                        .font(Theme.font(14, .regular))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.ink))

                        Button("Decline") {
                            Task { await viewModel.decline(request) }
                        }
                        .font(Theme.font(14, .regular))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                    }
                    .padding(14)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
                }
            }
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Friends")

            if viewModel.friends.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.friends) { friend in
                        NavigationLink(value: UserProfileNavigationTarget(
                            sub: friend.friendSub,
                            initialUsername: friend.friendUsername
                        )) {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color(hex: "C5B5F5").opacity(0.5))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(String(friend.friendUsername.prefix(1)).uppercased())
                                            .font(Theme.font(18))
                                            .foregroundStyle(Theme.ink)
                                    )

                                Text(friend.friendUsername)
                                    .font(Theme.font(16, .regular))
                                    .foregroundStyle(Theme.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(Theme.font(13, .regular))
                                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                            }
                            .padding(14)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2")
                .font(Theme.font(37, .regular))
                .foregroundStyle(Theme.textSecondary)
            Text("No friends yet")
                .font(Theme.font(17, .regular))
                .foregroundStyle(Theme.textPrimary)
            Text("Search for people using the + button")
                .font(Theme.font(14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
