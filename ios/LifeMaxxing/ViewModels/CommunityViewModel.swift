import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class CommunityViewModel {
    var community: Community?
    var leaderboard: [CommunityLeaderboardEntry] = []
    var feedPosts: [CommunityFeedPost] = []
    var isLoading = false
    var isJoining = false
    var isUploadingPhoto = false
    var uploadError: String?
    var errorMessage: String?
    var isMember = false

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
            }
            if isMember {
                feedPosts = (try? await CommunitiesAPI.shared.getCommunityFeed(id: communityId)) ?? []
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
