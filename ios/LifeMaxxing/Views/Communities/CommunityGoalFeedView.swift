import SwiftUI
import PhotosUI

struct CommunityGoalFeedView: View {
    let communityId: String
    @State private var viewModel: CommunityGoalViewModel
    @State private var showCompletionSheet = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    init(communityId: String, goal: CommunityGoal) {
        self.communityId = communityId
        _viewModel = State(initialValue: CommunityGoalViewModel(communityId: communityId, goal: goal))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    goalHeaderCard
                    completionActionCard
                    feedSection
                }
                .padding(20)
            }
            .refreshable { await viewModel.loadFeed() }
        }
        .navigationTitle(viewModel.goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadFeed() }
        .sheet(isPresented: $showCompletionSheet) {
            GoalCompletionSheet(viewModel: viewModel) {
                showCompletionSheet = false
            }
        }
        .onChange(of: viewModel.submitSuccess) { _, success in
            if success { showCompletionSheet = false }
        }
    }

    // MARK: - Goal Header

    private var goalHeaderCard: some View {
        HStack(spacing: 14) {
            Text(viewModel.goal.emoji)
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.goal.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: viewModel.goal.trackingType == .photo ? "camera.fill"
                          : viewModel.goal.trackingType == .text ? "text.bubble.fill"
                          : "camera.badge.plus")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    Text(viewModel.goal.trackingType.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let desc = viewModel.goal.description {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Completion CTA

    @ViewBuilder
    private var completionActionCard: some View {
        if viewModel.goal.myCompletion == nil {
            Button { showCompletionSheet = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Complete Today's Goal")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        } else {
            Button { showCompletionSheet = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.accentGreen)
                    Text("Completed Today — Update?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(16)
                .background(Theme.accentGreen.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.accentGreen.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Feed

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Completions")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            if viewModel.isLoadingFeed && viewModel.feedPosts.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 40)
            } else if viewModel.feedPosts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32)).foregroundStyle(Theme.textSecondary.opacity(0.4))
                    Text("No completions yet today")
                        .font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                    Text("Be the first!")
                        .font(.system(size: 12)).foregroundStyle(Theme.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 32)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.feedPosts) { post in
                        completionCard(post: post)
                    }
                }
            }
        }
    }

    private func completionCard(post: CommunityGoalCompletion) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let photoUrl = post.photoUrl {
                AsyncImage(url: URL(string: photoUrl)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(maxWidth: .infinity).frame(height: 200).clipped()
                    default:
                        Color(hex: "E8E8E4").frame(maxWidth: .infinity).frame(height: 200)
                            .overlay(ProgressView())
                    }
                }
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 16, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0, topTrailingRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    userAvatar(post: post)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(post.isMe ? "You" : post.username)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            if post.isMe {
                                Text("you")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Theme.accentGreen)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Theme.accentGreen.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(timeAgo(post.completedAt))
                            .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                }

                if let text = post.text, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(post.photoUrl != nil
                ? UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16,
                                         bottomTrailingRadius: 16, topTrailingRadius: 0, style: .continuous)
                : UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16,
                                         bottomTrailingRadius: 16, topTrailingRadius: 16, style: .continuous))
        }
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func userAvatar(post: CommunityGoalCompletion) -> some View {
        Group {
            if let url = post.avatarUrl.flatMap(URL.init) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        initialsCircle(post.username)
                    }
                }
            } else {
                initialsCircle(post.username)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }

    private func initialsCircle(_ username: String) -> some View {
        ZStack {
            Circle().fill(Color(hex: "C5B5F5").opacity(0.5))
            Text(String(username.prefix(1)).uppercased())
                .font(.system(size: 14, weight: .bold)).foregroundStyle(Theme.ink)
        }
    }

    private func timeAgo(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return "" }
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60 { return "just now" }
        if s < 3600 { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }
}

// MARK: - Goal Completion Sheet

struct GoalCompletionSheet: View {
    @Bindable var viewModel: CommunityGoalViewModel
    let onDismiss: () -> Void

    @State private var text = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        if let err = viewModel.submitError {
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(hex: "FF4444"))
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "FF4444").opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        if viewModel.goal.trackingType.needsPhoto {
                            photoSection
                        }

                        if viewModel.goal.trackingType.needsText {
                            textSection
                        }

                        submitButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle(viewModel.goal.myCompletion == nil ? "Complete Goal" : "Update Completion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                    selectedImage = UIImage(data: data)
                }
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photo")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 200).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Theme.accentGreen, lineWidth: 2)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.surfaceSecondary)
                            .frame(maxWidth: .infinity).frame(height: 160)
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.textSecondary.opacity(0.5))
                            Text("Tap to add photo")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Message")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                Text("\(text.count)/500")
                    .font(.system(size: 11))
                    .foregroundStyle(text.count > 450 ? Color(hex: "FF4444") : Theme.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Share your thoughts or takeaway…")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                        .padding(.horizontal, 14).padding(.top, 12)
                }
                TextEditor(text: $text)
                    .font(.system(size: 14))
                    .frame(minHeight: 100, maxHeight: 180)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text) { _, v in if v.count > 500 { text = String(v.prefix(500)) } }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.surfaceSecondary, lineWidth: 1)
            )
        }
    }

    private var submitButton: some View {
        let canSubmit: Bool = {
            if viewModel.goal.trackingType.needsPhoto && selectedImageData == nil
                && viewModel.goal.myCompletion?.hasPhoto != true { return false }
            if viewModel.goal.trackingType.needsText && text.trimmingCharacters(in: .whitespaces).isEmpty { return false }
            return true
        }()

        return Button {
            Task { await viewModel.submit(text: text.isEmpty ? nil : text, imageData: selectedImageData) }
        } label: {
            Group {
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text(viewModel.goal.myCompletion == nil ? "Submit" : "Update")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(canSubmit ? Theme.ink : Theme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!canSubmit || viewModel.isSubmitting)
    }
}
