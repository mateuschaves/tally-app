import AppKit
import Combine

/// Sets up the floating widget and the system-wide hotkeys once the app launches.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let store = AppStore()
    private var panelController: PanelController?
    private var hotKeys: HotKeyCenter?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Accessory app: no Dock icon, no app menu bar (also set via LSUIElement).
        NSApp.setActivationPolicy(.accessory)

        panelController = PanelController(store: store)

        // Global hotkeys (Carbon, no accessibility permission needed), kept in
        // sync with Preferências → Atalhos. Re-recording or toggling a shortcut
        // republishes `store.shortcuts`, which re-registers everything.
        hotKeys = HotKeyCenter { [weak self] id in
            Task { @MainActor in self?.store.runAction(id) }
        }
        store.$shortcuts
            .sink { [weak self] shortcuts in
                Task { @MainActor in self?.hotKeys?.apply(shortcuts) }
            }
            .store(in: &cancellables)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
