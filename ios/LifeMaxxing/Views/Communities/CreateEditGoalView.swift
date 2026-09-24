import SwiftUI

struct CreateEditGoalView: View {
    @State private var draft: CommunityGoalDraft
    let onSave: (CommunityGoalDraft) -> Void
    let onCancel: () -> Void

    @State private var showEmojiInput = false

    private let emojiSuggestions = [
        "⭐","🙏","💪","📚","🧘","🏃","🌅","✝️","☪️","🕍","☯️","🎯","📝","🥗","💧","😴","🎨","🎵","🌿","❤️"
    ]

    init(draft: CommunityGoalDraft, onSave: @escaping (CommunityGoalDraft) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        emojiSection
                        nameSection
                        descriptionSection
                        trackingTypeSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(draft.name.isEmpty ? "New Goal" : draft.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onSave(draft) }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Emoji

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Icon")

            VStack(spacing: 12) {
                // Large preview
                Text(draft.emoji)
                    .font(.system(size: 52))
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                // Quick picks
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 8) {
                    ForEach(emojiSuggestions, id: \.self) { emoji in
                        Button {
                            draft.emoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 22))
                                .frame(width: 36, height: 36)
                                .background(draft.emoji == emoji
                                            ? Theme.accentGreen.opacity(0.2)
                                            : Theme.surfaceSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Goal Name")
            TextField("e.g. Morning Devotions", text: $draft.name)
                .font(.system(size: 16))
                .padding(14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onChange(of: draft.name) { _, v in if v.count > 60 { draft.name = String(v.prefix(60)) } }
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                label("Description")
                Text("(optional)")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            ZStack(alignment: .topLeading) {
                if draft.description.isEmpty {
                    Text("Describe what members should do…")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                        .padding(.horizontal, 14).padding(.top, 12)
                }
                TextEditor(text: $draft.description)
                    .font(.system(size: 14))
                    .frame(height: 80)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .onChange(of: draft.description) { _, v in if v.count > 200 { draft.description = String(v.prefix(200)) } }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Tracking Type

    private var trackingTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("How should members complete this goal?")

            VStack(spacing: 8) {
                ForEach(CommunityGoal.TrackingType.allCases, id: \.self) { type in
                    Button { draft.trackingType = type } label: {
                        HStack(spacing: 14) {
                            Image(systemName: type == .photo ? "camera.fill"
                                  : type == .text ? "text.bubble.fill"
                                  : "camera.badge.plus")
                                .font(.system(size: 18))
                                .foregroundStyle(draft.trackingType == type ? Theme.accentGreen : Theme.textSecondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(trackingTypeSubtitle(type))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()

                            ZStack {
                                Circle()
                                    .strokeBorder(draft.trackingType == type ? Theme.accentGreen : Theme.surfaceSecondary, lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                if draft.trackingType == type {
                                    Circle().fill(Theme.accentGreen).frame(width: 12, height: 12)
                                }
                            }
                        }
                        .padding(14)
                        .background(draft.trackingType == type ? Theme.accentGreen.opacity(0.06) : Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(draft.trackingType == type ? Theme.accentGreen.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func trackingTypeSubtitle(_ type: CommunityGoal.TrackingType) -> String {
        switch type {
        case .photo: return "Members submit a photo as proof"
        case .text: return "Members share a short written reflection"
        case .both: return "Members submit both a photo and a message"
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)
    }
}
