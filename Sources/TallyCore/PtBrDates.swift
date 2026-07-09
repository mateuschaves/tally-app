import Foundation

/// pt-BR date/time formatting matching the prototype's `toLocaleDateString/Time`
/// calls. Centralized so display and the copyable report text stay consistent.
public enum PtBrDates {

    /// Gregorian calendar in the current time zone, pt-BR locale — the reference
    /// used for "today", history offsets and weekend detection.
    public static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pt_BR")
        return cal
    }

    private static func formatter(_ dateFormat: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.calendar = calendar
        f.dateFormat = dateFormat
        return f
    }

    /// e.g. "quinta-feira, 9 de julho" — weekday long, day numeric, month long.
    /// Matches `toLocaleDateString('pt-BR', { weekday:'long', day:'numeric', month:'long' })`.
    public static func long(_ date: Date) -> String {
        return formatter("EEEE, d 'de' MMMM").string(from: date)
    }

    /// e.g. "quinta-feira, 9 de jul" — weekday long, day numeric, month short (no dot).
    public static func short(_ date: Date) -> String {
        return formatter("EEEE, d 'de' MMM").string(from: date)
            .replacingOccurrences(of: ".", with: "")
    }

    /// e.g. "qui, 9 de jul  14:32" — the menu-bar clock string.
    /// Matches the prototype's `clockStr` (weekday short + day + month short + time).
    public static func clockString(_ date: Date) -> String {
        let head = formatter("EEE, d 'de' MMM").string(from: date)
            .replacingOccurrences(of: ".", with: "")
        return head + "  " + time(date)
    }

    /// 24h time, e.g. "14:32".
    public static func time(_ date: Date) -> String {
        return formatter("HH:mm").string(from: date)
    }

    /// True for Saturday/Sunday (used by the report's weekend empty-state).
    public static func isWeekend(_ date: Date) -> Bool {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday ... 7 = Saturday
        return weekday == 1 || weekday == 7
    }
}
