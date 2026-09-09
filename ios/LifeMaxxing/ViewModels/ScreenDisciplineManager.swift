import Foundation
import Observation

@Observable
final class ScreenDisciplineManager {
    static let shared = ScreenDisciplineManager()

    private enum K {
        static let goalMinutes  = "sd_goal_minutes"
        static let todayMinutes = "sd_today_minutes"
        static let date         = "sd_date"
        static let submitted    = "sd_submitted"
    }

    private(set) var goalMinutes: Int = 180        // default 3h
    private(set) var todayMinutes: Int? = nil      // nil = not submitted today
    private(set) var isSubmittedToday: Bool = false

    var metGoalToday: Bool? {
        guard let m = todayMinutes else { return nil }
        return m <= goalMinutes
    }

    private init() { restore() }

    // MARK: - Actions

    func setGoal(_ minutes: Int) {
        goalMinutes = max(15, minutes)
        UserDefaults.standard.set(goalMinutes, forKey: K.goalMinutes)
    }

    func submitToday(_ minutes: Int) {
        todayMinutes = minutes
        isSubmittedToday = true
        save()
    }

    func reset() {
        todayMinutes = nil
        isSubmittedToday = false
        save()
    }

    // MARK: - Persistence

    func restore() {
        let saved = UserDefaults.standard.integer(forKey: K.goalMinutes)
        goalMinutes = saved > 0 ? saved : 180

        let today = todayUTC()
        let savedDate = UserDefaults.standard.string(forKey: K.date) ?? ""
        if savedDate == today {
            isSubmittedToday = UserDefaults.standard.bool(forKey: K.submitted)
            let minutes = UserDefaults.standard.integer(forKey: K.todayMinutes)
            todayMinutes = (isSubmittedToday && minutes >= 0) ? minutes : nil
        } else {
            isSubmittedToday = false
            todayMinutes = nil
        }
    }

    private func save() {
        UserDefaults.standard.set(todayUTC(), forKey: K.date)
        UserDefaults.standard.set(todayMinutes ?? -1, forKey: K.todayMinutes)
        UserDefaults.standard.set(isSubmittedToday, forKey: K.submitted)
    }

    private func todayUTC() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")!
        return f.string(from: Date())
    }
}
