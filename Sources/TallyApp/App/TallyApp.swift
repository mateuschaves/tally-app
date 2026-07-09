import SwiftUI

@main
struct TallyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The widget itself is an AppKit panel managed by PanelController; the
        // SwiftUI scenes here are just the menu-bar item and the Settings window.
        MenuBarExtra("Tally", systemImage: "circle.dashed.inset.filled") {
            MenuBarView()
                .environmentObject(appDelegate.store)
        }

        Settings {
            PreferencesView()
                .environmentObject(appDelegate.store)
        }
    }
}
