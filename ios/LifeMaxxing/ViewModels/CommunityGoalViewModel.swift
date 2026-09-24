import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class CommunityGoalViewModel {
    var goal: CommunityGoal
    var feedPosts: [CommunityGoalCompletion] = []
    var isLoadingFeed = false
    var isSubmitting = false
    var submitError: String?
    var submitSuccess = false

    private let communityId: String

    init(communityId: String, goal: CommunityGoal) {
        self.communityId = communityId
        self.goal = goal
    }

    var hasCompletedToday: Bool { goal.myCompletion != nil }

    func loadFeed() async {
        isLoadingFeed = true
        defer { isLoadingFeed = false }
        if let posts = try? await CommunitiesAPI.shared.getCommunityGoalFeed(
            communityId: communityId, goalId: goal.goalId) {
            feedPosts = posts
        }
    }

    func submit(text: String?, imageData: Data?) async {
        isSubmitting = true
        submitError = nil
        submitSuccess = false
        defer { isSubmitting = false }
        do {
            var s3Key: String? = nil
            if goal.trackingType.needsPhoto, let data = imageData {
                let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.8) ?? data
                let urlResponse = try await CommunitiesAPI.shared.getCommunityGoalUploadUrl(
                    communityId: communityId, goalId: goal.goalId)
                try await CommunitiesAPI.shared.uploadCommunityPhoto(compressed, to: urlResponse.uploadUrl)
                s3Key = urlResponse.s3Key
            }
            try await CommunitiesAPI.shared.completeCommunityGoal(
                communityId: communityId, goalId: goal.goalId,
                photoS3Key: s3Key, text: text?.isEmpty == false ? text : nil)
            submitSuccess = true
            await loadFeed()
        } catch {
            submitError = error.localizedDescription
        }
    }
}
