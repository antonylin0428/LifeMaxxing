import Foundation

extension Error {
    /// True for task cancellation, which isn't a real failure - just the
    /// in-flight request getting torn down along with its `.task` (e.g. a
    /// `.page`-style TabView rebuilding a tab's view during its initial
    /// layout pass). Callers should silently ignore this rather than
    /// surface it as a user-facing error.
    var isCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}
