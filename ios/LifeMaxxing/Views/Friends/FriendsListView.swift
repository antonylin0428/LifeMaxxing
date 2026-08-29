import SwiftUI

struct FriendsListView: View {
    @State private var viewModel = FriendsViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if !viewModel.received.isEmpty {
                        pendingSection
                    }
                    friendsSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable { await viewModel.load() }
            .overlay {
                if viewModel.isLoading && viewModel.friends.isEmpty { LoadingView() }
            }
        }
        .navigationTitle("Friends")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink { LeaderboardView() } label: {
                    Image(systemName: "list.number")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { AddFriendView() } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .medium))
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
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                            )

                        Text(request.requesterUsername)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        Button("Accept") {
                            Task { await viewModel.accept(request) }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.ink))

                        Button("Decline") {
                            Task { await viewModel.decline(request) }
                        }
                        .font(.system(size: 13, weight: .semibold))
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
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hex: "C5B5F5").opacity(0.5))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(friend.friendUsername.prefix(1)).uppercased())
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                )

                            Text(friend.friendUsername)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()
                        }
                        .padding(14)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.2")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.textSecondary)
            Text("No friends yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Search for people using the + button")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
