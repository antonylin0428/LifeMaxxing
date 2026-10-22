import StoreKit
import Foundation
import Observation

@Observable
@MainActor
final class PurchaseService {
    static let shared = PurchaseService()

    // Consumable: buying this grants one community-creation credit, and can
    // be bought repeatedly for additional communities. (The old
    // "com.lifemaxxing.app.community_creation" product was a non-consumable
    // one-time unlock and can't be converted - Apple doesn't allow changing
    // a product's type after creation - so this is a new product ID.)
    private let communityProductId = "com.lifemaxxing.app.community_creation_credit"

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

    /// "Restore" doesn't mean what it used to: this product is consumable,
    /// and Apple deliberately never surfaces consumables via
    /// Transaction.currentEntitlements (there's no client-side "ownership"
    /// state to restore - a credit is either spent or it isn't). Our server
    /// ledger (communityCreateCredits on the Users row) is already the real
    /// source of truth and already comes back on every GET /me, so "restore"
    /// here just means "re-sync from the server" - kept as a visible action
    /// since App Store review sometimes expects one even for consumables.
    func restorePurchases() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        let me = try await ProfileAPI.shared.getMe()
        return me.communityCreateCredits > 0 || me.hasCommunityAccess
    }

    private func verifyWithBackend(jwsString: String) async throws -> Bool {
        struct VerifyBody: Encodable {
            let signedTransactionInfo: String
        }
        struct VerifyResponse: Decodable {
            let communityCreateCredits: Int
        }
        let body = VerifyBody(signedTransactionInfo: jwsString)
        let response: VerifyResponse = try await APIClient.shared.request(
            path: "/purchases/verify",
            method: .post,
            body: body
        )
        return response.communityCreateCredits > 0
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
