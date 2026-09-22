import Foundation
import Observation
import UIKit

@Observable
@MainActor
final class ProfileSettingsViewModel {
    private var originalUsername = ""

    var username: String = "" {
        didSet { validateUsername() }
    }
    var selectedImageData: Data?
    var previewImage: UIImage?
    var isSaving = false
    var saveError: String?
    var saveSuccess = false
    var usernameError: String?

    var hasChanges: Bool {
        username != originalUsername || selectedImageData != nil
    }

    var canSave: Bool {
        hasChanges && usernameError == nil && !username.isEmpty
    }

    var charCount: Int { username.count }

    func load(from user: User) {
        originalUsername = user.username
        username = user.username
        usernameError = nil
    }

    func applyPhoto(_ data: Data) {
        selectedImageData = data
        previewImage = UIImage(data: data)
    }

    private func validateUsername() {
        if username.count < 3 {
            usernameError = username.isEmpty ? nil : "At least 3 characters required"
        } else if username.count > 20 {
            usernameError = "Maximum 20 characters"
        } else if username.range(of: "^[a-zA-Z0-9_]+$", options: .regularExpression) == nil {
            usernameError = "Letters, numbers, and underscores only"
        } else {
            usernameError = nil
        }
    }

    func save() async {
        validateUsername()
        guard canSave else { return }

        isSaving = true
        saveError = nil
        saveSuccess = false
        defer { isSaving = false }

        do {
            var newAvatarKey: String?
            if let imageData = selectedImageData {
                let compressed = UIImage(data: imageData)?.jpegData(compressionQuality: 0.8) ?? imageData
                let urlResponse = try await ProfileAPI.shared.getAvatarUploadUrl()
                try await ProfileAPI.shared.uploadAvatar(compressed, to: urlResponse.uploadUrl)
                newAvatarKey = urlResponse.s3Key
            }

            let updatedUsername = username != originalUsername ? username : nil
            try await ProfileAPI.shared.updateProfile(
                username: updatedUsername,
                avatarKey: newAvatarKey
            )
            saveSuccess = true
        } catch {
            saveError = error.localizedDescription
        }
    }
}
