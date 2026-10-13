import SwiftUI

/// Only reachable after purchasing community access (see ProfileView's NavigationLink) -
/// the server re-checks hasCommunityAccess independently on submit regardless.
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
                        .font(Theme.font(27))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Create a space for people to compete together")
                        .font(Theme.font(15))
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

    // MARK: Success → navigate into the new community

    private func successView(community: Community) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "B0E8AC").opacity(0.4))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(Theme.font(41, .regular))
                    .foregroundStyle(Color(hex: "2A8A28"))
            }
            VStack(spacing: 8) {
                Text("Community Created!")
                    .font(Theme.font(23))
                    .foregroundStyle(Theme.textPrimary)
                Text(community.name)
                    .font(Theme.font(19, .regular))
                    .foregroundStyle(Theme.textSecondary)
            }
            NavigationLink(destination: CommunityDetailView(
                communityId: community.communityId,
                initialName: community.name
            )) {
                Text("View Community")
                    .font(Theme.font(16, .regular))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color(hex: "7A5CF5"))
                    .clipShape(Capsule())
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
