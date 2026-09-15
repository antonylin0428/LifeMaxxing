import SwiftUI

struct MyCommunityListView: View {
    @State private var viewModel = MyCommunityListViewModel()
    @State private var navigateToCreate = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.communities.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.communities.isEmpty {
                emptyState
            } else {
                communityList
            }
        }
        .navigationTitle("My Communities")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: CreateCommunityView()) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var communityList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.communities) { community in
                    NavigationLink(destination: CommunityDetailView(
                        communityId: community.communityId,
                        initialName: community.name
                    )) {
                        communityCard(community: community)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
    }

    private func communityCard(community: Community) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: "C5B5F5").opacity(0.25))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "7A5CF5"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(community.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(community.memberCount ?? 0) members · by \(community.createdByUsername)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "C5B5F5").opacity(0.3))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.3.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(Color(hex: "7A5CF5"))
            }
            VStack(spacing: 8) {
                Text("No communities yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Create a community and challenge others to compete with you.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            NavigationLink(destination: CreateCommunityView()) {
                Text("Create a Community")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "7A5CF5"))
                    .clipShape(Capsule())
            }
        }
        .padding(40)
    }
}
