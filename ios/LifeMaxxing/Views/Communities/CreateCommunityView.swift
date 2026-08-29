import SwiftUI

/// Only reachable for premium users (see ProfileView's NavigationLink) -
/// the server re-checks isPremium independently on submit regardless.
struct CreateCommunityView: View {
    @State private var viewModel = CreateCommunityViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if let community = viewModel.createdCommunity {
                successView(community: community)
            } else {
                formView
            }

            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("Create Community")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Form

    private var formView: some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Community")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Create a space for people to compete together")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 8)

                VStack(spacing: 12) {
                    ThemedTextField("Community name", text: $viewModel.name, iconName: "person.3")
                    ThemedTextField("Description (optional)", text: $viewModel.description,
                                    iconName: "text.alignleft")
                }

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                Button("Create Community") {
                    Task { await viewModel.createCommunity() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isLoading ||
                          viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: Success

    private func successView(community: Community) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "B0E8AC").opacity(0.4))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Color(hex: "2A8A28"))
            }

            VStack(spacing: 8) {
                Text("Community Created!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(community.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                if let description = community.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
