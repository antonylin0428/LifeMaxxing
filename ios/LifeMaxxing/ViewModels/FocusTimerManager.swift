import Foundation
import Observation

struct FocusSession: Codable, Identifiable {
    var id: UUID = UUID()
    let startedAt: Date
    let submittedAt: Date
    let seconds: TimeInterval
}

@Observable
final class FocusTimerManager {
    static let shared = FocusTimerManager()

    private enum K {
        static let accumulated      = "focus_accumulated_v2"
        static let date             = "focus_date_v2"
        static let submitted        = "focus_submitted_v2"
        static let sessions         = "focus_sessions_v3"
        static let sessionStartedAt = "focus_session_started_at_v3"
    }

    private(set) var isRunning             = false
    private(set) var accumulatedSeconds: TimeInterval = 0
    private(set) var isSubmittedToday      = false
    private(set) var displaySeconds: TimeInterval = 0
    private(set) var sessions: [FocusSession] = []

    private var sessionStart: Date?
    private var currentSessionStartedAt: Date?

    private init() { restore() }

    // MARK: - Computed

    var hasTime: Bool { displaySeconds > 0 }

    var totalSecondsToday: TimeInterval {
        sessions.reduce(0) { $0 + $1.seconds } + displaySeconds
    }

    // MARK: - Formatting

    func formatted(_ seconds: TimeInterval) -> String {
        let t = Int(seconds)
        let h = t / 3600, m = (t % 3600) / 60, s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    // MARK: - Controls

    func toggleTimer() { isRunning ? pause() : startSession() }

    func handleBackground() { pause() }

    func startSession() {
        guard !isRunning else { return }
        if currentSessionStartedAt == nil {
            currentSessionStartedAt = Date()
        }
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

    func tick() {
        guard let start = sessionStart else { return }
        displaySeconds = accumulatedSeconds + Date().timeIntervalSince(start)
    }

    // Call after a successful completeTask API response (first session)
    // OR directly for additional sessions — no API needed.
    func markSubmitted() {
        pause()
        let secs = accumulatedSeconds
        guard secs > 0 else { return }
        sessions.append(FocusSession(
            startedAt: currentSessionStartedAt ?? Date(),
            submittedAt: Date(),
            seconds: secs
        ))
        accumulatedSeconds = 0
        displaySeconds = 0
        currentSessionStartedAt = nil
        isSubmittedToday = true
        save()
    }

    func reset() {
        sessionStart = nil
        currentSessionStartedAt = nil
        isRunning = false
        accumulatedSeconds = 0
        displaySeconds = 0
        isSubmittedToday = false
        sessions = []
        [K.accumulated, K.date, K.submitted, K.sessions, K.sessionStartedAt]
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: - Restore

    func restore() {
        let today = todayUTC()
        let savedDate = UserDefaults.standard.string(forKey: K.date) ?? ""

        if savedDate == today {
            accumulatedSeconds = UserDefaults.standard.double(forKey: K.accumulated)
            isSubmittedToday   = UserDefaults.standard.bool(forKey: K.submitted)
            sessionStart = nil
            isRunning    = false

            if let data = UserDefaults.standard.data(forKey: K.sessions),
               let decoded = try? JSONDecoder().decode([FocusSession].self, from: data) {
                sessions = decoded
            }
            let ts = UserDefaults.standard.double(forKey: K.sessionStartedAt)
            if ts > 0 { currentSessionStartedAt = Date(timeIntervalSince1970: ts) }
        } else {
            accumulatedSeconds       = 0
            isSubmittedToday         = false
            sessionStart             = nil
            isRunning                = false
            sessions                 = []
            currentSessionStartedAt  = nil
            save()
        }
        tick()
    }

    // MARK: - Persistence

    private func save() {
        UserDefaults.standard.set(todayUTC(),         forKey: K.date)
        UserDefaults.standard.set(accumulatedSeconds, forKey: K.accumulated)
        UserDefaults.standard.set(isSubmittedToday,   forKey: K.submitted)
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: K.sessions)
        }
        if let ts = currentSessionStartedAt {
            UserDefaults.standard.set(ts.timeIntervalSince1970, forKey: K.sessionStartedAt)
        } else {
            UserDefaults.standard.removeObject(forKey: K.sessionStartedAt)
        }
    }

    private func todayUTC() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone   = TimeZone(identifier: "UTC")!
        return f.string(from: Date())
    }
}
