import SwiftUI
import PhotosUI

struct CommunityDetailView: View {
    let communityId: String
    var initialName: String? = nil

    @State private var viewModel: CommunityViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(communityId: String, initialName: String? = nil) {
        self.communityId = communityId
        self.initialName = initialName
        _viewModel = State(initialValue: CommunityViewModel(communityId: communityId))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if viewModel.isLoading && viewModel.community == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .navigationTitle(viewModel.community?.name ?? initialName ?? "Community")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    await viewModel.uploadPhoto(data)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let community = viewModel.community {
                    communityHeader(community: community)
                }

                if !viewModel.isMember {
                    joinButton
                } else {
                    feedSection
                }

                if !viewModel.leaderboard.isEmpty {
                    leaderboardSection
                }
            }
            .padding(20)
        }
    }

    // MARK: - Feed

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Feed")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                photoPickerButton
            }

            if viewModel.isUploadingPhoto {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Posting…")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            if let err = viewModel.uploadError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "FF4444"))
            }

            if viewModel.feedPosts.isEmpty && !viewModel.isUploadingPhoto {
                emptyFeedPlaceholder
            } else {
                feedGrid
            }
        }
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.myPost == nil ? "camera.fill" : "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                Text(viewModel.myPost == nil ? "Post Photo" : "Retake")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Theme.ink)
            .clipShape(Capsule())
        }
        .disabled(viewModel.isUploadingPhoto)
    }

    private var emptyFeedPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 32))
                .foregroundStyle(Theme.textSecondary.opacity(0.4))
            Text("No photos yet today")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
            Text("Be the first to post!")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var feedGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.feedPosts) { post in
                feedCell(post: post)
            }
        }
    }

    private func feedCell(post: CommunityFeedPost) -> some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: post.photoUrl)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(post.isMe ? Theme.accentGreen : Color.clear, lineWidth: 2)
                        )
                case .failure:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.surfaceSecondary)
                        .frame(width: 100, height: 100)
                        .overlay(Image(systemName: "photo").foregroundStyle(Theme.textSecondary))
                default:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.surfaceSecondary)
                        .frame(width: 100, height: 100)
                        .overlay(ProgressView())
                }
            }
            .frame(width: 100, height: 100)

            Text(post.isMe ? "you" : post.username)
                .font(.system(size: 11, weight: post.isMe ? .bold : .regular))
                .foregroundStyle(post.isMe ? Theme.accentGreen : Theme.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Join

    private var joinButton: some View {
        Button {
            Task { await viewModel.join() }
        } label: {
            Group {
                if viewModel.isJoining {
                    ProgressView().tint(.white)
                } else {
                    Text("Join Community")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.accentGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(viewModel.isJoining)
    }

    // MARK: - Community Header

    private func communityHeader(community: Community) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "C5B5F5").opacity(0.3))
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color(hex: "7A5CF5"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(community.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Created by \(community.createdByUsername)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(community.memberCount ?? viewModel.leaderboard.count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("members")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            if let desc = community.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leaderboard")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, entry in
                    leaderboardRow(entry: entry, rank: index + 1)
                    if index < viewModel.leaderboard.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
    }

    private func leaderboardRow(entry: CommunityLeaderboardEntry, rank: Int) -> some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(rank <= 3 ? Color(hex: "F5A623") : Theme.textSecondary)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.system(size: 14, weight: entry.isMe ? .bold : .medium))
                        .foregroundStyle(Theme.textPrimary)
                    if entry.isMe {
                        Text("you")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accentGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accentGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if let rank = entry.rank {
                    Text(rank.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Text("\(entry.totalXP) XP")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(entry.isMe ? Theme.accentGreen.opacity(0.05) : Color.clear)
    }
}
