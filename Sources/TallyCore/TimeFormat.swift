import Foundation

/// Time formatting helpers, ported 1:1 from the prototype (`fmtClock`, `fmtDur`, `fmtMin`).
public enum TimeFormat {

    private static func pad2(_ n: Int) -> String { String(format: "%02d", n) }

    /// Running clock for the active timer.
    /// `h:mm:ss` when there are hours, otherwise `mm:ss`.
    /// Ported from `fmtClock`.
    public static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let ss = s % 60
        return h > 0 ? "\(h):\(pad2(m)):\(pad2(ss))" : "\(pad2(m)):\(pad2(ss))"
    }

    /// Compact duration label. `Ns` under a minute, `Nm` under an hour,
    /// otherwise `Hh MMm`. Ported from `fmtDur`.
    public static func duration(_ seconds: Int) -> String {
        let s = max(0, seconds)
        if s < 60 { return "\(s)s" }
        let m = Int((Double(s) / 60).rounded())
        if m < 60 { return "\(m)m" }
        return "\(m / 60)h \(pad2(m % 60))m"
    }

    /// Estimate/minutes label. `Nm` under an hour, `Hh` on whole hours,
    /// otherwise `HhMM` (no space). Ported from `fmtMin`.
    public static func minutes(_ minutes: Double) -> String {
        let m = Int(minutes.rounded())
        if m < 60 { return "\(m)m" }
        return (m % 60 == 0) ? "\(m / 60)h" : "\(m / 60)h\(pad2(m % 60))"
    }

    /// Convenience for integer minutes.
    public static func minutes(_ minutes: Int) -> String {
        return TimeFormat.minutes(Double(minutes))
    }
}
