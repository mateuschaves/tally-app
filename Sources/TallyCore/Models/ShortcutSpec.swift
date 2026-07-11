import Foundation

/// A configurable keyboard shortcut, ported from the prototype's
/// `defaultShortcuts()` entries. Pure data: the app layer decides how to
/// register it (Carbon global hotkey, menu key-equivalent or local handling).
public struct ShortcutSpec: Equatable, Codable, Identifiable, Sendable {

    /// Stable action identifier (`new`, `complete`, `pause`, …).
    public let id: String
    /// Section in the shortcuts screen: `CAPTURA`, `FOCO` or `JANELA`.
    public let group: String
    /// Small glyph shown in the row's icon chip (e.g. `＋`, `✓`, `⚑`).
    public let icon: String
    public let name: String
    /// Secondary line under the name (empty when none).
    public let hint: String
    /// Display keycaps in press order, e.g. `["⇧", "⌘", "D"]`.
    public var keys: [String]
    /// macOS virtual key code of the non-modifier key (`kVK_*`), when known.
    /// `nil` means the combo can't be registered as a system-wide hotkey.
    public var keyCode: UInt16?
    /// Carbon modifier mask (cmdKey | optionKey | controlKey | shiftKey).
    public var carbonModifiers: UInt32
    public var enabled: Bool

    public init(
        id: String, group: String, icon: String, name: String, hint: String = "",
        keys: [String], keyCode: UInt16? = nil, carbonModifiers: UInt32 = 0,
        enabled: Bool = true
    ) {
        self.id = id
        self.group = group
        self.icon = icon
        self.name = name
        self.hint = hint
        self.keys = keys
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
        self.enabled = enabled
    }

    /// Canonical identity of the key combination (used for conflict checks),
    /// mirroring the prototype's `keysStr` (`keys.join('+')`).
    public var comboString: String { keys.joined(separator: "+") }
}

public enum ShortcutCatalog {

    /// Carbon modifier masks (from Carbon's `Events.h`; redeclared here so
    /// TallyCore stays Foundation-only).
    public enum Modifier {
        public static let command: UInt32 = 0x0100 // cmdKey
        public static let shift: UInt32 = 0x0200   // shiftKey
        public static let option: UInt32 = 0x0800  // optionKey
        public static let control: UInt32 = 0x1000 // controlKey
    }

    /// The prototype's `defaultShortcuts()`, with the native key codes needed
    /// to register them (kVK_ANSI_* / kVK_Return / kVK_Escape).
    public static var defaults: [ShortcutSpec] {
        [
            ShortcutSpec(id: "new", group: "CAPTURA", icon: "＋", name: "Nova tarefa",
                         hint: "Abre a captura rápida", keys: ["⌘", "K"],
                         keyCode: 40, carbonModifiers: Modifier.command),
            ShortcutSpec(id: "confirmAdd", group: "CAPTURA", icon: "⏎", name: "Adicionar / confirmar",
                         hint: "No campo de captura", keys: ["⏎"],
                         keyCode: 36, carbonModifiers: 0),
            ShortcutSpec(id: "complete", group: "FOCO", icon: "✓", name: "Concluir tarefa atual",
                         keys: ["⇧", "⌘", "D"],
                         keyCode: 2, carbonModifiers: Modifier.shift | Modifier.command),
            ShortcutSpec(id: "block", group: "FOCO", icon: "⚑", name: "Marcar impedimento",
                         keys: ["⇧", "⌘", "B"],
                         keyCode: 11, carbonModifiers: Modifier.shift | Modifier.command),
            ShortcutSpec(id: "pause", group: "FOCO", icon: "❙❙", name: "Pausar / retomar cronômetro",
                         keys: ["⌘", "."],
                         keyCode: 47, carbonModifiers: Modifier.command),
            ShortcutSpec(id: "toggleWidget", group: "JANELA", icon: "⧉", name: "Mostrar / ocultar Tally",
                         keys: ["⌥", "⌘", "T"],
                         keyCode: 17, carbonModifiers: Modifier.option | Modifier.command),
            ShortcutSpec(id: "report", group: "JANELA", icon: "☰", name: "Abrir Resumo do dia",
                         keys: ["⌘", "R"],
                         keyCode: 15, carbonModifiers: Modifier.command),
            ShortcutSpec(id: "prefs", group: "JANELA", icon: "⚙", name: "Abrir Preferências",
                         keys: ["⌘", ","],
                         keyCode: 43, carbonModifiers: Modifier.command),
            ShortcutSpec(id: "close", group: "JANELA", icon: "⎋", name: "Fechar janelas abertas",
                         keys: ["esc"],
                         keyCode: 53, carbonModifiers: 0)
        ]
    }

    /// Display order of the groups (also drives the screen's section order).
    public static let groups = ["CAPTURA", "FOCO", "JANELA"]

    /// Merge a persisted snapshot with the defaults, ported from the prototype's
    /// load path: every default action always exists; saved entries only carry
    /// over their recorded combo and enabled flag. Unknown saved ids are dropped.
    public static func merge(saved: [ShortcutSpec]) -> [ShortcutSpec] {
        guard !saved.isEmpty else { return defaults }
        let byId = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return defaults.map { def in
            guard let s = byId[def.id] else { return def }
            var out = def
            if !s.keys.isEmpty {
                out.keys = s.keys
                out.keyCode = s.keyCode
                out.carbonModifiers = s.carbonModifiers
            }
            out.enabled = s.enabled
            return out
        }
    }

    /// The enabled shortcut (other than `excluding`) already using `combo`,
    /// mirroring the prototype's clash check on record.
    public static func conflict(
        in shortcuts: [ShortcutSpec], combo: String, excluding id: String
    ) -> ShortcutSpec? {
        shortcuts.first { $0.id != id && $0.enabled && $0.comboString == combo }
    }

    /// Filter rows for the search field: matches name or hint,
    /// case-insensitively; empty query matches everything.
    public static func matches(_ spec: ShortcutSpec, query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return true }
        return spec.name.lowercased().contains(q) || spec.hint.lowercased().contains(q)
    }
}
