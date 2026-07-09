import SwiftUI
import AppKit

/// Contents of the "Tally" menu-bar item. For an accessory (LSUIElement) app the
/// system menu bar isn't shown, so these commands live here + the global ⌘K.
struct MenuBarView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Button("Nova tarefa") { store.openQuickEntry() }
            .keyboardShortcut("k")

        Button("Resumo do dia") { store.openReport() }

        Divider()

        Button("Mostrar widget") { store.onShowWidget?() }

        SettingsLink {
            Text("Preferências…")
        }
        .keyboardShortcut(",")

        Divider()

        Button("Sair do Tally") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
    }
}
