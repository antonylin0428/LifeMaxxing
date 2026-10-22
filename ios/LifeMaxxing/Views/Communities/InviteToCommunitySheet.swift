import SwiftUI

struct InviteToCommunitySheet: View {
    let community: Community
    let isCreator: Bool
    @Bindable var viewModel: CommunityViewModel
    let onDismiss: () -> Void

    private var shareText: String {
        "Join my community \"\(community.name)\" on LifeMaxxing! Use invite code: \(community.inviteCode ?? "")"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        codeSection

                        if isCreator {
                            friendsSection
                        }

                        if let err = viewModel.inviteError {
                            Text(err)
                                .font(Theme.font(13))
                                .foregroundStyle(Color(hex: "FF4444"))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Invite to \(community.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { onDismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .task { if isCreator { await viewModel.loadFriendsForInvite() } }
        }
        .presentationDetents([.medium, .large])
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invite Code")
                .font(Theme.font(14))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack {
                Text(community.inviteCode ?? "—")
                    .font(Theme.font(29, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(3)
                Spacer()
                if let code = community.inviteCode {
                    ShareLink(item: shareText) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(Theme.font(14, .regular))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.ink)
                        .clipShape(Capsule())
                    }
                    .accessibilityHint(code)
                }
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text("Anyone with this code can join from the Communities screen.")
                .font(Theme.font(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invite a Friend")
                .font(Theme.font(14))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            if viewModel.friends.isEmpty {
                Text("Add friends first to invite them directly.")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.friends) { friend in
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hex: "C5B5F5").opacity(0.5))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Text(String(friend.friendUsername.prefix(1)).uppercased())
                                        .font(Theme.font(15))
                                        .foregroundStyle(Theme.ink)
                                )
                            Text(friend.friendUsername)
                                .font(Theme.font(15, .regular))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()

                            let invited = viewModel.invitedFriendSubs.contains(friend.friendSub)
                            Button {
                                Task { await viewModel.inviteFriend(friend.friendSub) }
                            } label: {
                                Text(invited ? "Invited" : "Invite")
                                    .font(Theme.font(13, .regular))
                                    .foregroundStyle(invited ? Theme.textSecondary : .white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(invited ? AnyShapeStyle(Theme.surfaceSecondary) : AnyShapeStyle(Theme.ink))
                                    .clipShape(Capsule())
                            }
                            .disabled(invited)
                        }
                        .padding(12)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
    }
}
