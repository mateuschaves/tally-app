import Foundation

/// Task priority. Ported from the prototype's `prios` map:
/// `{ alta: {c:'#FF453A', l:'Alta'}, media: {c:'#FFD60A', l:'Média'}, baixa: {c:'#98989D', l:'Baixa'} }`.
public enum Priority: String, Codable, CaseIterable, Sendable {
    case alta
    case media
    case baixa

    /// Human label shown in the UI (pt-BR), matching the prototype exactly.
    public var label: String {
        switch self {
        case .alta:  return "Alta"
        case .media: return "Média"
        case .baixa: return "Baixa"
        }
    }

    /// Hex color used for the priority dot/badge.
    public var colorHex: String {
        switch self {
        case .alta:  return "#FF453A"
        case .media: return "#FFD60A"
        case .baixa: return "#98989D"
        }
    }

    /// Parse a priority token from quick-entry (`!alta`, `!média`, `!baixa`).
    /// Mirrors the JS: lowercase then replace `é` with `e` (`média` → `media`).
    public static func fromToken(_ raw: String) -> Priority? {
        let normalized = raw.lowercased().replacingOccurrences(of: "é", with: "e")
        return Priority(rawValue: normalized)
    }
}
