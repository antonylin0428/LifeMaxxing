import Foundation

/// Local-only placeholder for the Home dashboard's Achievements section.
/// There is no backend table or endpoint for achievements yet - this is
/// static mock data so the prototype UI has something to render. Replace
/// with a real `GET /me/achievements` model once that exists server-side.
struct Achievement: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let isUnlocked: Bool

    static let mockForPrototype: [Achievement] = [
        Achievement(id: "streak-7", title: "7-Day Streak", iconName: "flame.fill", isUnlocked: true),
        Achievement(id: "first-workout", title: "First Workout", iconName: "figure.strengthtraining.traditional", isUnlocked: true),
        Achievement(id: "scholar", title: "Scholar", iconName: "book.fill", isUnlocked: true),
        Achievement(id: "xp-rush", title: "XP Rush", iconName: "bolt.fill", isUnlocked: false),
        Achievement(id: "inner-peace", title: "Inner Peace", iconName: "leaf.fill", isUnlocked: false),
    ]
}
