import Foundation
import Observation

@Observable
@MainActor
final class CommunityViewModel {
    var community: Community?
    var leaderboard: [CommunityLeaderboardEntry] = []
    var isLoading = false
    var isJoining = false
    var errorMessage: String?
    var isMember = false

    private let communityId: String

    init(communityId: String) {
        self.communityId = communityId
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let mySub = try? await AuthService.shared.currentUserSub()
            async let communityTask = CommunitiesAPI.shared.getCommunity(id: communityId)
            async let leaderboardTask = CommunitiesAPI.shared.getCommunityLeaderboard(id: communityId)
            let (c, lb) = try await (communityTask, leaderboardTask)
            community = c
            leaderboard = lb.leaderboard
            if let sub = mySub {
                isMember = lb.leaderboard.contains { $0.sub == sub }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func join() async {
        isJoining = true
        defer { isJoining = false }
        do {
            try await CommunitiesAPI.shared.joinCommunity(id: communityId)
            isMember = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@Observable
@MainActor
final class MyCommunityListViewModel {
    var communities: [Community] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            communities = try await CommunitiesAPI.shared.listMyCommunities()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
