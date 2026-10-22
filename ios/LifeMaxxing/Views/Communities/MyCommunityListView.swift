import SwiftUI

struct MyCommunityListView: View {
    @State private var viewModel = MyCommunityListViewModel()
    @State private var navigateToCreate = false
    @State private var joinedCommunity: Community?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.communities.isEmpty {
                ScrollView { CommunityListSkeletonView() }
            } else if viewModel.communities.isEmpty && viewModel.invites.isEmpty {
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
                        .font(Theme.font(17, .regular))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .navigationDestination(item: $joinedCommunity) { community in
            CommunityDetailView(communityId: community.communityId, initialName: community.name)
        }
    }

    private var communityList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                joinByCodeSection

                if !viewModel.invites.isEmpty {
                    invitesSection
                }

                if !viewModel.communities.isEmpty {
                    VStack(spacing: 12) {
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
                }
            }
            .padding(20)
        }
    }

    // MARK: - Join by Code

    private var joinByCodeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Join with a Code")
            HStack(spacing: 10) {
                TextField("e.g. 7K3QF9", text: Bindable(viewModel).joinByCodeText)
                    .font(Theme.font(16, .regular))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )

                Button {
                    Task {
                        if let community = await viewModel.joinByCode() {
                            joinedCommunity = community
                        }
                    }
                } label: {
                    if viewModel.isJoiningByCode {
                        ProgressView().tint(.white)
                    } else {
                        Text("Join")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 84)
                .disabled(viewModel.isJoiningByCode || viewModel.joinByCodeText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let err = viewModel.joinByCodeError {
                Text(err)
                    .font(Theme.font(13))
                    .foregroundStyle(Color(hex: "FF4444"))
            }
        }
    }

    // MARK: - Pending Invites

    private var invitesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Invites")
            VStack(spacing: 8) {
                ForEach(viewModel.invites) { invite in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Theme.surfaceSecondary)
                                .frame(width: 44, height: 44)
                            Image(systemName: "envelope.fill")
                                .font(Theme.font(16, .regular))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(invite.communityName)
                                .font(Theme.font(15, .regular))
                                .foregroundStyle(Theme.textPrimary)
                            Text("from \(invite.invitedByUsername)")
                                .font(Theme.font(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Button("Accept") { Task { await viewModel.acceptInvite(invite) } }
                            .font(Theme.font(13, .regular))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Capsule().fill(Theme.ink))
                        Button("Decline") { Task { await viewModel.declineInvite(invite) } }
                            .font(Theme.font(13, .regular))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .overlay(Capsule().strokeBorder(Theme.border, lineWidth: 1))
                    }
                    .padding(14)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                }
            }
        }
    }

    private func communityCard(community: Community) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.3.fill")
                    .font(Theme.font(19, .regular))
                    .foregroundStyle(Theme.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(community.name)
                    .font(Theme.font(16, .regular))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(community.memberCount ?? 0) members · by \(community.createdByUsername)")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(Theme.font(13, .regular))
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
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.3.fill")
                    .font(Theme.font(35, .regular))
                    .foregroundStyle(Theme.accent)
            }
            VStack(spacing: 8) {
                Text("No communities yet")
                    .font(Theme.font(21))
                    .foregroundStyle(Theme.textPrimary)
                Text("Create a community and challenge others to compete with you.")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            NavigationLink(destination: CreateCommunityView()) {
                Text("Create a Community")
                    .font(Theme.font(16, .regular))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.ink)
                    .clipShape(Capsule())
            }
        }
        .padding(40)
    }
}
