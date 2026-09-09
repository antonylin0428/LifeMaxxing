import Foundation
import Observation

@Observable
final class FocusTimerManager {
    static let shared = FocusTimerManager()

    private enum K {
        static let sessionStart = "focus_session_start_v2"
        static let accumulated  = "focus_accumulated_v2"
        static let date         = "focus_date_v2"
        static let submitted    = "focus_submitted_v2"
    }

    private(set) var isRunning        = false
    private(set) var accumulatedSeconds: TimeInterval = 0
    private(set) var isSubmittedToday = false
    // Driven by tick() every second
    private(set) var displaySeconds: TimeInterval = 0

    private var sessionStart: Date?

    private init() { restore() }

    // MARK: - Public

    var hasTime: Bool { displaySeconds > 0 }

    func formatted(_ seconds: TimeInterval) -> String {
        let t = Int(seconds)
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    func toggleTimer() { isRunning ? pause() : startSession() }

    // Called by RootView scene-phase observer when app goes to background
    func handleBackground() { pause() }

    func startSession() {
        guard !isRunning, !isSubmittedToday else { return }
        sessionStart = Date()
        isRunning = true
    }

    func pause() {
        guard let start = sessionStart else {
            isRunning = false
            return
        }
        accumulatedSeconds += Date().timeIntervalSince(start)
        sessionStart = nil
        isRunning = false
        displaySeconds = accumulatedSeconds
        save()
    }

    // Call every second from Timer.publish while the view is visible
    func tick() {
        guard let start = sessionStart else { return }
        displaySeconds = accumulatedSeconds + Date().timeIntervalSince(start)
    }

    // Call after a successful completeTask API response
    func markSubmitted() {
        pause()
        isSubmittedToday = true
        save()
    }

    // Call on sign-out
    func reset() {
        sessionStart = nil
        isRunning = false
        accumulatedSeconds = 0
        displaySeconds = 0
        isSubmittedToday = false
        [K.sessionStart, K.accumulated, K.date, K.submitted]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: - Restore

    func restore() {
        let today = todayUTC()
        let savedDate = UserDefaults.standard.string(forKey: K.date) ?? ""

        if savedDate == today {
            accumulatedSeconds = UserDefaults.standard.double(forKey: K.accumulated)
            isSubmittedToday   = UserDefaults.standard.bool(forKey: K.submitted)
            // Any leftover sessionStart means the app was force-killed while running.
            // Leaving the app stops the timer, so discard that uncounted interval.
            UserDefaults.standard.removeObject(forKey: K.sessionStart)
            sessionStart = nil
            isRunning    = false
        } else {
            // New UTC day — reset
            accumulatedSeconds = 0
            isSubmittedToday   = false
            sessionStart       = nil
            isRunning          = false
            save()
        }
        tick()
    }

    // MARK: - Persistence

    private func save() {
        UserDefaults.standard.set(todayUTC(),         forKey: K.date)
        UserDefaults.standard.set(accumulatedSeconds, forKey: K.accumulated)
        UserDefaults.standard.set(isSubmittedToday,  forKey: K.submitted)
        if sessionStart == nil {
            UserDefaults.standard.removeObject(forKey: K.sessionStart)
        }
    }

    private func todayUTC() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone   = TimeZone(identifier: "UTC")!
        return f.string(from: Date())
    }
}
