import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    let user: User
    @State private var viewModel = ProfileSettingsViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    avatarSection
                    usernameSection
                    Spacer().frame(height: 4)
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }

            // Full-screen error toast
            if let error = viewModel.saveError {
                VStack {
                    Spacer()
                    ErrorBanner(message: error)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .zIndex(1)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.saveError)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load(from: user) }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    viewModel.applyPhoto(data)
                }
            }
        }
        .onChange(of: viewModel.saveSuccess) { _, success in
            if success { dismiss() }
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    avatarImage
                    cameraBadge
                }
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                Text(user.username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Tap photo to change")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
    }

    @ViewBuilder
    private var avatarImage: some View {
        let size: CGFloat = 100
        if let preview = viewModel.previewImage {
            Image(uiImage: preview)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Theme.background, lineWidth: 3))
        } else if let urlString = user.avatarUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Theme.background, lineWidth: 3))
                default:
                    initialsCircle(size: size)
                }
            }
        } else {
            initialsCircle(size: size)
        }
    }

    private func initialsCircle(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: "E2E0DB"))
                .frame(width: size, height: size)
            Text(String(user.username.prefix(1)).uppercased())
                .font(.system(size: size * 0.38, weight: .black))
                .foregroundStyle(Theme.ink)
        }
    }

    private var cameraBadge: some View {
        ZStack {
            Circle()
                .fill(Theme.ink)
                .frame(width: 32, height: 32)
                .overlay(Circle().strokeBorder(Theme.background, lineWidth: 3))
            Image(systemName: "camera.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .offset(x: 4, y: 4)
    }

    // MARK: - Username

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("USERNAME")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.8)

            HStack(spacing: 12) {
                Image(systemName: "at")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 18)

                TextField("username", text: $viewModel.username)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                Spacer()

                // Character count
                Text("\(viewModel.charCount)/20")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(viewModel.charCount > 20
                                     ? Color(hex: "FF4444")
                                     : Theme.textSecondary)
                    .monospacedDigit()

                // Validation icon
                if !viewModel.username.isEmpty {
                    Image(systemName: viewModel.usernameError == nil
                          ? "checkmark.circle.fill"
                          : "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(viewModel.usernameError == nil
                                         ? Color(hex: "4CAF50")
                                         : Color(hex: "FF4444"))
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.2), value: viewModel.usernameError)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        viewModel.usernameError != nil ? Color(hex: "FF4444").opacity(0.4) :
                        (viewModel.username != "" && viewModel.usernameError == nil ? Color(hex: "4CAF50").opacity(0.4) : Color.clear),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)

            // Validation message
            if let error = viewModel.usernameError {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 12))
                }
                .foregroundStyle(Color(hex: "FF4444"))
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.25), value: viewModel.usernameError)
            } else {
                Text("Letters, numbers, and underscores · 3–20 characters")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(viewModel.canSave ? Theme.ink : Theme.surfaceSecondary)

                if viewModel.isSaving {
                    HStack(spacing: 10) {
                        ProgressView()
                            .tint(viewModel.canSave ? .white : Theme.textSecondary)
                        Text("Saving…")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(viewModel.canSave ? .white : Theme.textSecondary)
                    }
                } else {
                    Text(viewModel.hasChanges ? "Save Changes" : "No Changes")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(viewModel.canSave ? .white : Theme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
        }
        .disabled(!viewModel.canSave || viewModel.isSaving)
        .animation(.easeInOut(duration: 0.2), value: viewModel.canSave)
    }
}
