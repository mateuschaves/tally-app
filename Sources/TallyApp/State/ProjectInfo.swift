import Foundation

/// A project and its dot color. Colors live in the app layer (not `TallyCore`).
struct ProjectInfo: Codable, Equatable, Identifiable {
    var name: String
    var colorHex: String
    var id: String { name }
}

enum ProjectPalette {
    /// The four seeded projects with the exact colors from the prototype's `projColors`.
    static let defaults: [ProjectInfo] = [
        ProjectInfo(name: "Backend", colorHex: "#0A84FF"),
        ProjectInfo(name: "Design", colorHex: "#BF5AF2"),
        ProjectInfo(name: "Reuniões", colorHex: "#FF9F0A"),
        ProjectInfo(name: "Geral", colorHex: "#98989D")
    ]

    /// Colors assigned to user-created projects. The first (`#5AC8FA`) matches
    /// the prototype's `canonProj`; the rest keep additional projects distinct.
    static let customColors = ["#5AC8FA", "#FF375F", "#64D2FF", "#FFD60A", "#AF52DE", "#30D158", "#FF9F0A"]
}
