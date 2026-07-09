import Foundation

/// Natural-language quick-entry parser. Ported from the prototype's `parseQE`.
///
/// Recognizes, in order:
///  - `#projeto`      → project token (raw; canonicalized by the app layer)
///  - `!alta|!média|!baixa` → priority
///  - `30m` / `2h` / `90 min` / `1,5h` → estimate in minutes
/// Whatever remains (whitespace-collapsed, trimmed) is the title.
public enum QuickParse {

    public struct Result: Equatable, Sendable {
        public var title: String
        public var project: String?
        public var priority: Priority?
        /// Estimate in minutes.
        public var estimate: Int?

        public init(title: String, project: String? = nil, priority: Priority? = nil, estimate: Int? = nil) {
            self.title = title
            self.project = project
            self.priority = priority
            self.estimate = estimate
        }
    }

    public static func parse(_ input: String) -> Result {
        // The JS pads with spaces so the `\b` boundaries and leading `#`/`!` work
        // regardless of position. We do the same.
        var text = " " + input + " "
        var project: String?
        var priority: Priority?
        var estimate: Int?

        if let match = firstMatch(in: text, pattern: "#([A-Za-zÀ-ÿ0-9_-]+)") {
            project = match.groups[1]
            text = replacingFirst(text, match.full, with: " ")
        }

        if let match = firstMatch(in: text, pattern: "!(alta|m[ée]dia|baixa)", options: [.caseInsensitive]) {
            priority = Priority.fromToken(match.groups[1])
            text = replacingFirst(text, match.full, with: " ")
        }

        if let match = firstMatch(in: text, pattern: "(\\d+(?:[.,]\\d+)?)\\s*(h|horas?|m|min)\\b", options: [.caseInsensitive]) {
            let numberString = match.groups[1].replacingOccurrences(of: ",", with: ".")
            if let value = Double(numberString) {
                let unit = match.groups[2].lowercased()
                estimate = unit.hasPrefix("h") ? Int((value * 60).rounded()) : Int(value.rounded())
            }
            text = replacingFirst(text, match.full, with: " ")
        }

        let title = text
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        return Result(title: title, project: project, priority: priority, estimate: estimate)
    }

    // MARK: - Regex helpers

    private struct Match {
        let full: String
        /// Index 0 is the full match; 1..n are capture groups.
        let groups: [String]
    }

    private static func firstMatch(in string: String, pattern: String, options: NSRegularExpression.Options = []) -> Match? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let ns = string as NSString
        guard let result = regex.firstMatch(in: string, options: [], range: NSRange(location: 0, length: ns.length)) else {
            return nil
        }
        var groups: [String] = []
        for i in 0..<result.numberOfRanges {
            let range = result.range(at: i)
            groups.append(range.location == NSNotFound ? "" : ns.substring(with: range))
        }
        return Match(full: groups[0], groups: groups)
    }

    /// Replace the first occurrence of `target` with `replacement`
    /// (mirrors JS `String.replace(substring, ...)`).
    private static func replacingFirst(_ string: String, _ target: String, with replacement: String) -> String {
        guard let range = string.range(of: target) else { return string }
        return string.replacingCharacters(in: range, with: replacement)
    }
}
