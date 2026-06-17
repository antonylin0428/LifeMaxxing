import Foundation
import Observation

@Observable
@MainActor
final class FriendsViewModel {
    var friends: [Friendship] = []
    var received: [FriendRequest] = []
    var sent: [SentFriendRequest] = []
    var searchUsername = ""
    var searchResult: UserSearchResult?
    var errorMessage: String?
    var isLoading = false

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            friends = try await FriendsAPI.shared.listFriends()
            let pending = try await FriendsAPI.shared.listPendingRequests()
            received = pending.received
            sent = pending.sent
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search() async {
        errorMessage = nil
        do {
            searchResult = try await FriendsAPI.shared.search(username: searchUsername)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendRequest(toSub sub: String) async {
        do {
            try await FriendsAPI.shared.sendRequest(toSub: sub)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ request: FriendRequest) async {
        do {
            try await FriendsAPI.shared.acceptRequest(fromSub: request.requesterSub)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(_ request: FriendRequest) async {
        do {
            try await FriendsAPI.shared.declineRequest(fromSub: request.requesterSub)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
