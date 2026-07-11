import SwiftUI

@main
struct TallyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The widget itself is an AppKit panel managed by PanelController; the
        // SwiftUI scenes here are just the menu-bar item and the Settings window.
        // The status-item glyph is the app icon's motif (disc + check) as a
        // template image, so it adapts to the menu bar's light/dark appearance.
        MenuBarExtra("Tally", image: "MenuBarIcon") {
            MenuBarView()
                .environmentObject(appDelegate.store)
        }

        Settings {
            PreferencesView()
                .environmentObject(appDelegate.store)
        }
    }
}
