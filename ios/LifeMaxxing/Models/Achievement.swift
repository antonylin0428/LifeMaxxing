import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let isUnlocked: Bool

    private static let catalog: [(id: String, title: String, description: String, icon: String)] = [
        ("first-workout", "First Workout",
         "Complete your very first Fitness workout.",
         "figure.strengthtraining.traditional"),
        ("scholar", "Scholar",
         "Complete your first Focus or Study session.",
         "book.fill"),
        ("streak-7", "7-Day Streak",
         "Maintain a 7-day streak in any single category.",
         "flame.fill"),
        ("iron-will", "Iron Will",
         "Maintain a 30-day streak in any single category.",
         "bolt.shield.fill"),
        ("centurion", "Centurion",
         "Earn a total of 100 XP across all categories.",
         "star.fill"),
    ]

    static func fromServerGrants(_ grants: [String]?) -> [Achievement] {
        let grantSet = Set(grants ?? [])
        return catalog.map { item in
            Achievement(id: item.id, title: item.title, description: item.description,
                        iconName: item.icon, isUnlocked: grantSet.contains(item.id))
        }
    }
}
