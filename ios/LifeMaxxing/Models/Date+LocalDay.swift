import Foundation

extension Date {
    /// YYYY-MM-DD in the device's current local timezone. The server computes
    /// "today" the same way (per-user `timezone` on the Users record, synced
    /// from `TimeZone.current.identifier` after sign-in) — every "is this done
    /// today" check on the client must go through this, not a hardcoded UTC
    /// formatter, or it'll disagree with the server right at the day boundary.
    var localDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: self)
    }
}
