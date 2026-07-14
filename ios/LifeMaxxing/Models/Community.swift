import Foundation

/// Mirrors the POST /communities response. Creation is premium-gated
/// server-side; there's no list/browse/join endpoint yet - that's separate
/// scope from the premium gate this model exists to support.
struct Community: Codable, Identifiable {
    var id: String { communityId }
    let communityId: String
    let name: String
    let description: String?
    let createdBy: String
    let createdByUsername: String
    let createdAt: String
}
