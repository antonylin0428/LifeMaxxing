import SwiftUI

/// Only reachable for premium users (see ProfileView's NavigationLink) -
/// the server re-checks isPremium independently on submit regardless.
struct CreateCommunityView: View {
    @State private var viewModel = CreateCommunityViewModel()

    var body: some View {
        Form {
            if let community = viewModel.createdCommunity {
                Section {
                    Text("Community created! 🎉")
                        .font(.headline)
                    Text(community.name)
                        .font(.title3.bold())
                    if let description = community.description {
                        Text(description)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                @Bindable var viewModel = viewModel
                TextField("Community Name", text: $viewModel.name)
                TextField("Description (optional)", text: $viewModel.description)

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                Button("Create Community") {
                    Task { await viewModel.createCommunity() }
                }
                .disabled(viewModel.isLoading || viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .overlay {
            if viewModel.isLoading { LoadingView() }
        }
        .navigationTitle("Create Community")
    }
}
