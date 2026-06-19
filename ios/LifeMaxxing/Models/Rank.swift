import Foundation

/// Mirrors backend/layers/shared/.../rankLadder.js - display-only on the
/// client. The server is always the source of truth for which rank a user
/// actually holds; this enum just needs the same key strings to label it.
enum Rank: String, Codable, CaseIterable {
    case lowTierNormie1 = "LOW_TIER_NORMIE_1"
    case lowTierNormie2 = "LOW_TIER_NORMIE_2"
    case lowTierNormie3 = "LOW_TIER_NORMIE_3"
    case midTierNormie1 = "MID_TIER_NORMIE_1"
    case midTierNormie2 = "MID_TIER_NORMIE_2"
    case midTierNormie3 = "MID_TIER_NORMIE_3"
    case highTierNormie1 = "HIGH_TIER_NORMIE_1"
    case highTierNormie2 = "HIGH_TIER_NORMIE_2"
    case highTierNormie3 = "HIGH_TIER_NORMIE_3"
    case chadLight = "CHAD_LIGHT"
    case chad = "CHAD"

    var displayName: String {
        switch self {
        case .lowTierNormie1: return "Low Tier Normie 1"
        case .lowTierNormie2: return "Low Tier Normie 2"
        case .lowTierNormie3: return "Low Tier Normie 3"
        case .midTierNormie1: return "Mid Tier Normie 1"
        case .midTierNormie2: return "Mid Tier Normie 2"
        case .midTierNormie3: return "Mid Tier Normie 3"
        case .highTierNormie1: return "High Tier Normie 1"
        case .highTierNormie2: return "High Tier Normie 2"
        case .highTierNormie3: return "High Tier Normie 3"
        case .chadLight: return "Chad Light"
        case .chad: return "Chad"
        }
    }

    /// XP needed to reach this rank. Mirrors RANKS[*].xpRequired in
    /// rankLadder.js - display-only, used to draw progress bars on the
    /// client. The server alone decides which rank a user actually holds.
    var xpRequired: Int {
        switch self {
        case .lowTierNormie1: return 0
        case .lowTierNormie2: return 100
        case .lowTierNormie3: return 250
        case .midTierNormie1: return 500
        case .midTierNormie2: return 900
        case .midTierNormie3: return 1400
        case .highTierNormie1: return 2100
        case .highTierNormie2: return 3000
        case .highTierNormie3: return 4200
        case .chadLight: return 8000
        case .chad: return 18000
        }
    }

    /// The next rank up the ladder, or nil if already at Chad. Note that
    /// reaching `next.xpRequired` XP is necessary but not always sufficient -
    /// Chad Light/Chad also gate on consistency server-side.
    var next: Rank? {
        let all = Rank.allCases
        guard let index = all.firstIndex(of: self), index + 1 < all.count else { return nil }
        return all[index + 1]
    }
}
