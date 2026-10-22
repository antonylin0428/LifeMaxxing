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
                        if draft.trackingType == .numeric {
                            numericConfigSection
                        }
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
                        .font(Theme.font(16, .regular))
                        .foregroundStyle(Theme.ink)
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var canSave: Bool {
        guard !draft.name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if draft.trackingType == .numeric {
            guard let value = Double(draft.targetValue), value > 0 else { return false }
            guard !draft.unit.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        }
        return true
    }

    // MARK: - Numeric Config

    private var numericConfigSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            label("Target")

            HStack(spacing: 10) {
                TextField("150", text: $draft.targetValue)
                    .keyboardType(.decimalPad)
                    .font(Theme.font(17))
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                TextField("g protein", text: $draft.unit)
                    .font(Theme.font(17))
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .onChange(of: draft.unit) { _, v in if v.count > 20 { draft.unit = String(v.prefix(20)) } }
            }

            VStack(spacing: 8) {
                ForEach(CommunityGoal.Direction.allCases, id: \.self) { d in
                    Button { draft.direction = d } label: {
                        HStack(spacing: 10) {
                            Text(d.displayName)
                                .font(Theme.font(15, .regular))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if draft.direction == d {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accentGreen)
                            }
                        }
                        .padding(12)
                        .background(draft.direction == d ? Theme.accentGreen.opacity(0.06) : Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let target = Double(draft.targetValue), !draft.unit.isEmpty {
                Text("Members log a number each day; \(draft.direction == .atMost ? "at most" : "at least") \(formattedTarget(target)) \(draft.unit) earns the day's XP.")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func formattedTarget(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(format: "%g", value)
    }

    // MARK: - Emoji

    private var emojiSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            label("Icon")

            VStack(spacing: 12) {
                // Large preview
                Text(draft.emoji)
                    .font(Theme.font(53))
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
                                .font(Theme.font(23))
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
                .font(Theme.font(17))
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
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            ZStack(alignment: .topLeading) {
                if draft.description.isEmpty {
                    Text("Describe what members should do…")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                        .padding(.horizontal, 14).padding(.top, 12)
                }
                TextEditor(text: $draft.description)
                    .font(Theme.font(15))
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
                            Image(systemName: trackingTypeIcon(type))
                                .font(Theme.font(19))
                                .foregroundStyle(draft.trackingType == type ? Theme.accentGreen : Theme.textSecondary)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.displayName)
                                    .font(Theme.font(16, .regular))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(trackingTypeSubtitle(type))
                                    .font(Theme.font(13))
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

    private func trackingTypeIcon(_ type: CommunityGoal.TrackingType) -> String {
        switch type {
        case .photo: return "camera.fill"
        case .text: return "text.bubble.fill"
        case .both: return "camera.badge.plus"
        case .numeric: return "number"
        }
    }

    private func trackingTypeSubtitle(_ type: CommunityGoal.TrackingType) -> String {
        switch type {
        case .photo: return "Members submit a photo as proof"
        case .text: return "Members share a short written reflection"
        case .both: return "Members submit both a photo and a message"
        case .numeric: return "Members log a number against a daily target"
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(14, .regular))
            .foregroundStyle(Theme.textSecondary)
    }
}
