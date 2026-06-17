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
}
