import SwiftUI

struct AddFriendView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var didSendRequest = false

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            TextField("Username", text: $viewModel.searchUsername)
                .textInputAutocapitalization(.never)
            Button("Search") {
                didSendRequest = false
                Task { await viewModel.search() }
            }

            if let result = viewModel.searchResult {
                HStack {
                    Text(result.username)
                    Spacer()
                    Button(didSendRequest ? "Sent" : "Add Friend") {
                        Task {
                            await viewModel.sendRequest(toSub: result.sub)
                            didSendRequest = true
                        }
                    }
                    .disabled(didSendRequest)
                }
            }

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
        }
        .navigationTitle("Add Friend")
    }
}
