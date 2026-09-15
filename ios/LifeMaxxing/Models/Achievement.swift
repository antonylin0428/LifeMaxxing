import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let isUnlocked: Bool

    // Full catalog — matches backend achievement IDs from completeTask Lambda.
    private static let catalog: [(id: String, title: String, icon: String)] = [
        ("first-workout", "First Workout",  "figure.strengthtraining.traditional"),
        ("scholar",       "Scholar",         "book.fill"),
        ("streak-7",      "7-Day Streak",    "flame.fill"),
        ("iron-will",     "Iron Will",       "bolt.shield.fill"),
        ("centurion",     "Centurion",       "star.fill"),
    ]

    /// Build the achievement list from the server's granted-ID set, marking each as
    /// unlocked or locked. Locked achievements are shown greyed out so users know what
    /// to aim for.
    static func fromServerGrants(_ grants: [String]?) -> [Achievement] {
        let grantSet = Set(grants ?? [])
        return catalog.map { item in
            Achievement(id: item.id, title: item.title, iconName: item.icon,
                        isUnlocked: grantSet.contains(item.id))
        }
    }
}
