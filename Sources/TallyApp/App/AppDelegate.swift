import AppKit
import Carbon.HIToolbox

/// Sets up the floating widget and the global ⌘K hotkey once the app launches.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let store = AppStore()
    private var panelController: PanelController?
    private var hotKey: GlobalHotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Accessory app: no Dock icon, no app menu bar (also set via LSUIElement).
        NSApp.setActivationPolicy(.accessory)

        panelController = PanelController(store: store)

        // ⌘K anywhere → quick entry (Carbon, no accessibility permission needed).
        hotKey = GlobalHotKey(keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(cmdKey)) { [weak self] in
            Task { @MainActor in self?.store.openQuickEntry() }
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
