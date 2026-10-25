import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class CommunityViewModel {
    var community: Community?
    var leaderboard: [CommunityLeaderboardEntry] = []
    var goals: [CommunityGoal] = []
    var feedPosts: [CommunityFeedPost] = []
    var isLoading = false
    var isJoining = false
    var isUploadingPhoto = false
    var uploadError: String?
    var errorMessage: String?
    var isMember = false
    var isCreator = false

    // Invite sheet state
    var friends: [Friendship] = []
    var invitedFriendSubs: Set<String> = []
    var inviteError: String?

    var myPost: CommunityFeedPost? { feedPosts.first { $0.isMe } }

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
                isCreator = c.createdBy == sub
            }
            if isMember {
                goals = (try? await CommunitiesAPI.shared.getCommunityGoals(id: communityId)) ?? []
                feedPosts = (try? await CommunitiesAPI.shared.getCommunityFeed(id: communityId)) ?? []
            }
        } catch is CancellationError {
            // A newer load() superseded this one (e.g. pull-to-refresh while
            // the initial .task load was still in flight) - not a real error.
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Same as above, surfaced from the underlying URLSession task instead.
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
            goals = (try? await CommunitiesAPI.shared.getCommunityGoals(id: communityId)) ?? []
            feedPosts = (try? await CommunitiesAPI.shared.getCommunityFeed(id: communityId)) ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadPhoto(_ imageData: Data) async {
        isUploadingPhoto = true
        uploadError = nil
        defer { isUploadingPhoto = false }
        do {
            let compressed = UIImage(data: imageData)?.jpegData(compressionQuality: 0.8) ?? imageData
            let urlResponse = try await CommunitiesAPI.shared.getCommunityFeedUploadUrl(id: communityId)
            try await CommunitiesAPI.shared.uploadCommunityPhoto(compressed, to: urlResponse.uploadUrl)
            try await CommunitiesAPI.shared.postCommunityPhoto(communityId: communityId, s3Key: urlResponse.s3Key)
            // Refresh feed to show new/updated post
            feedPosts = try await CommunitiesAPI.shared.getCommunityFeed(id: communityId)
        } catch {
            uploadError = error.localizedDescription
        }
    }

    func loadFriendsForInvite() async {
        friends = (try? await FriendsAPI.shared.listFriends()) ?? []
    }

    func inviteFriend(_ friendSub: String) async {
        inviteError = nil
        do {
            try await CommunitiesAPI.shared.inviteFriend(friendSub, toCommunity: communityId)
            invitedFriendSubs.insert(friendSub)
        } catch {
            inviteError = error.localizedDescription
        }
    }
}

@Observable
@MainActor
final class MyCommunityListViewModel {
    var communities: [Community] = []
    var invites: [CommunityInvite] = []
    var isLoading = false
    var errorMessage: String?

    var joinByCodeText = ""
    var isJoiningByCode = false
    var joinByCodeError: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let communitiesTask = CommunitiesAPI.shared.listMyCommunities()
            async let invitesTask = CommunitiesAPI.shared.listCommunityInvites()
            communities = try await communitiesTask
            invites = try await invitesTask
        } catch is CancellationError {
            // A newer load() superseded this one - not a real error.
        } catch let urlError as URLError where urlError.code == .cancelled {
            // Same as above, surfaced from the underlying URLSession task instead.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinByCode() async -> Community? {
        let code = joinByCodeText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return nil }
        isJoiningByCode = true
        joinByCodeError = nil
        defer { isJoiningByCode = false }
        do {
            let result = try await CommunitiesAPI.shared.joinCommunity(byCode: code)
            joinByCodeText = ""
            await load()
            return Community(
                communityId: result.communityId, name: result.name, description: nil,
                createdBy: "", createdByUsername: "", createdAt: "", memberCount: nil, inviteCode: nil
            )
        } catch {
            joinByCodeError = error.localizedDescription
            return nil
        }
    }

    func acceptInvite(_ invite: CommunityInvite) async {
        do {
            _ = try await CommunitiesAPI.shared.acceptCommunityInvite(invite.communityId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineInvite(_ invite: CommunityInvite) async {
        do {
            try await CommunitiesAPI.shared.declineCommunityInvite(invite.communityId)
            invites.removeAll { $0.id == invite.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
