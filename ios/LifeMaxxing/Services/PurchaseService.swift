import StoreKit
import Foundation
import Observation

@Observable
@MainActor
final class PurchaseService {
    static let shared = PurchaseService()

    private let communityProductId = "com.lifemaxxing.app.community_creation"

    var product: Product?
    var isLoading = false
    var errorMessage: String?

    private init() {}

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [communityProductId])
            product = products.first
        } catch {
            print("PurchaseService: failed to load product — \(error)")
        }
    }

    /// Initiates the StoreKit purchase flow, then verifies with the backend.
    /// Returns true if hasCommunityAccess was granted.
    func purchaseCommunityAccess() async throws -> Bool {
        guard let product else {
            throw PurchaseError.productNotLoaded
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Pass the user's Cognito sub as appAccountToken so the async Apple
        // webhook can also map the purchase back to this user.
        var purchaseOptions: Set<Product.PurchaseOption> = []
        if let subString = try? await AuthService.shared.currentUserSub(),
           let subUUID = UUID(uuidString: subString) {
            purchaseOptions.insert(.appAccountToken(subUUID))
        }

        let result = try await product.purchase(options: purchaseOptions)

        switch result {
        case .success(let verification):
            // verification.jwsRepresentation is the signed JWS string from Apple
            let jwsString = verification.jwsRepresentation
            switch verification {
            case .verified(let transaction):
                let granted = try await verifyWithBackend(jwsString: jwsString)
                await transaction.finish()
                return granted
            case .unverified:
                throw PurchaseError.unverifiedTransaction
            }
        case .pending:
            throw PurchaseError.pending
        case .userCancelled:
            throw PurchaseError.cancelled
        @unknown default:
            throw PurchaseError.unknown
        }
    }

    /// Restores any previously completed purchases. Returns true if access was restored.
    func restorePurchases() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        var restored = false
        for await result in Transaction.currentEntitlements {
            guard result.payloadData != nil else { continue }
            let jwsString = result.jwsRepresentation
            if case .verified(let transaction) = result,
               transaction.productID == communityProductId,
               transaction.revocationDate == nil {
                let granted = try await verifyWithBackend(jwsString: jwsString)
                if granted { restored = true }
                await transaction.finish()
            }
        }
        return restored
    }

    private func verifyWithBackend(jwsString: String) async throws -> Bool {
        struct VerifyBody: Encodable {
            let signedTransactionInfo: String
        }
        struct VerifyResponse: Decodable {
            let hasCommunityAccess: Bool
        }
        let body = VerifyBody(signedTransactionInfo: jwsString)
        let response: VerifyResponse = try await APIClient.shared.request(
            path: "/purchases/verify",
            method: .post,
            body: body
        )
        return response.hasCommunityAccess
    }
}

enum PurchaseError: LocalizedError {
    case productNotLoaded
    case unverifiedTransaction
    case pending
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotLoaded: return "Product unavailable. Check your connection and try again."
        case .unverifiedTransaction: return "Purchase could not be verified. Contact support."
        case .pending: return "Purchase is pending approval."
        case .cancelled: return nil
        case .unknown: return "Something went wrong. Try again."
        }
    }
}
