import Foundation

/// Mirrors an XPEvents ledger entry. Not used by the MVP UI yet (no history
/// feed screen), but the model exists so a future history view has
/// something concrete to decode against.
struct XPEvent: Codable, Identifiable {
    var id: String { "\(categoryId.rawValue)-\(createdAt)" }
    let categoryId: CategoryId
    let baseXP: Int
    let multiplierApplied: Double
    let finalXPAwarded: Int
    let eventType: String
    let createdAt: String
}
