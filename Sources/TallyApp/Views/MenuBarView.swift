import SwiftUI
import AppKit
import TallyCore

/// Contents of the "Tally" menu-bar item — the native home for the prototype's
/// menu bar (Arquivo/Tarefa/Exibir/Janela). Items show the user-configured
/// shortcuts from Preferências → Atalhos, so re-recording a combo updates the
/// menu labels too.
struct MenuBarView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Button("Nova tarefa…") { store.openQuickEntry() }
            .keyboardShortcut(shortcut("new"))

        Button("Novo projeto…") { store.openNewProject() }

        Button("Resumo do dia…") { store.openReport() }
            .keyboardShortcut(shortcut("report"))

        Divider()

        Button("Concluir tarefa atual") { store.completeCurrent() }
            .keyboardShortcut(shortcut("complete"))
            .disabled(!store.hasCurrent)

        Button("Marcar impedimento…") { store.blockCurrent() }
            .keyboardShortcut(shortcut("block"))
            .disabled(!store.hasCurrent)

        Button(store.paused ? "Retomar cronômetro" : "Pausar cronômetro") { store.togglePause() }
            .keyboardShortcut(shortcut("pause"))
            .disabled(!store.hasCurrent)

        Divider()

        Picker("Tema", selection: Binding(
            get: { store.themePreference },
            set: { store.setThemePreference($0) }
        )) {
            Text("Escuro").tag(ThemePreference.dark)
            Text("Claro").tag(ThemePreference.light)
            Text("Sistema").tag(ThemePreference.system)
        }

        Divider()

        Button(store.widgetVisible ? "Ocultar widget" : "Mostrar widget") {
            store.onToggleWidget?()
        }
        .keyboardShortcut(shortcut("toggleWidget"))

        Button("Centralizar widget") { store.onCenterWidget?() }

        SettingsLink {
            Text("Preferências…")
        }
        .keyboardShortcut(shortcut("prefs"))

        Divider()

        Button("Sair do Tally") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func shortcut(_ id: String) -> KeyboardShortcut? {
        guard let spec = store.shortcut(id), spec.enabled else { return nil }
        return KeyboardShortcutMapper.shortcut(for: spec)
    }
}

/// Maps a recorded `ShortcutSpec` onto SwiftUI's `KeyboardShortcut` so menu
/// items can display it. Combos without a representable key (or disabled ones)
/// simply show no label — the Carbon hotkey still works.
enum KeyboardShortcutMapper {

    static func shortcut(for spec: ShortcutSpec) -> KeyboardShortcut? {
        guard let last = spec.keys.last, let key = keyEquivalent(last) else { return nil }
        var modifiers: EventModifiers = []
        if spec.carbonModifiers & ShortcutCatalog.Modifier.command != 0 { modifiers.insert(.command) }
        if spec.carbonModifiers & ShortcutCatalog.Modifier.option != 0 { modifiers.insert(.option) }
        if spec.carbonModifiers & ShortcutCatalog.Modifier.control != 0 { modifiers.insert(.control) }
        if spec.carbonModifiers & ShortcutCatalog.Modifier.shift != 0 { modifiers.insert(.shift) }
        // Bare ⏎/esc/⌫ combos stay local to the capture fields and overlays;
        // surfacing them as menu key-equivalents would swallow normal typing.
        guard !modifiers.isEmpty else { return nil }
        return KeyboardShortcut(key, modifiers: modifiers)
    }

    private static func keyEquivalent(_ cap: String) -> KeyEquivalent? {
        switch cap {
        case "⏎": return .return
        case "esc": return .escape
        case "⌫": return .delete
        case "⇥": return .tab
        case "Espaço": return .space
        case "←": return .leftArrow
        case "→": return .rightArrow
        case "↑": return .upArrow
        case "↓": return .downArrow
        default:
            guard cap.count == 1, let ch = cap.lowercased().first else { return nil }
            return KeyEquivalent(ch)
        }
    }
}
