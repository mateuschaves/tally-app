import AppKit
import SwiftUI
import Combine

/// Owns the two AppKit windows — the floating widget and the shared full-screen
/// overlay — and keeps the overlay's visibility in sync with `store.overlay`.
/// The widget appears centered on launch and pins its top edge so it grows
/// downward; a drag repositions it and persists the new origin.
@MainActor
final class PanelController: NSObject, NSWindowDelegate {

    private let store: AppStore
    private var widgetPanel: FloatingPanel!
    private var overlayWindow: OverlayWindow!
    private var cancellables = Set<AnyCancellable>()
    private var pinnedTop: CGFloat?

    private static let widgetWidth: CGFloat = 312

    init(store: AppStore) {
        self.store = store
        super.init()
        setupWidget()
        setupOverlay()
        observeOverlay()
        store.onToggleWidget = { [weak self] in self?.toggleWidget() }
        store.onShowWidget = { [weak self] in self?.showWidget() }
        store.onHideWidget = { [weak self] in self?.hideWidget() }
    }

    // MARK: Widget

    private func setupWidget() {
        let root = CompactCardView()
            .environmentObject(store)
            .frame(width: Self.widgetWidth, alignment: .top)
            .fixedSize(horizontal: false, vertical: true)

        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = [.preferredContentSize]

        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: Self.widgetWidth, height: 420))
        panel.contentViewController = hosting
        panel.delegate = self
        widgetPanel = panel

        positionWidget()
        // Always show the widget on launch (centered).
        panel.orderFrontRegardless()
        store.widgetVisible = true
        // The SwiftUI content settles to its fitted height a beat after mounting,
        // so re-center once it has. Skip if the user already dragged the widget in
        // the meantime: a drag updates `pinnedTop`, so a changed value means we'd
        // be snapping their chosen position back to center — leave it alone.
        let topAtLaunch = pinnedTop
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 60_000_000)
            guard let self, self.pinnedTop == topAtLaunch else { return }
            self.positionWidget()
        }
    }

    private func positionWidget() {
        // Prefer the screen the panel actually sits on (multi-monitor), falling
        // back to the main screen before it has been placed.
        guard let screen = widgetPanel.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = widgetPanel.frame.size
        // Open centered on that screen's visible area.
        let origin = CGPoint(x: visible.midX - size.width / 2,
                             y: visible.midY - size.height / 2)
        widgetPanel.setFrameOrigin(origin)
        pinnedTop = widgetPanel.frame.maxY
    }

    func showWidget() {
        widgetPanel.orderFrontRegardless()
        store.widgetVisible = true
    }

    func hideWidget() {
        widgetPanel.orderOut(nil)
        store.widgetVisible = false
    }

    func toggleWidget() {
        if widgetPanel.isVisible { hideWidget() } else { showWidget() }
    }

    // MARK: Overlay

    private func setupOverlay() {
        let frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let root = OverlayRootView().environmentObject(store)
        let hosting = NSHostingController(rootView: root)
        hosting.sizingOptions = [] // fill the window; don't auto-size to content
        let window = OverlayWindow(contentRect: frame)
        window.contentViewController = hosting
        window.setFrame(frame, display: false)
        overlayWindow = window
    }

    private func observeOverlay() {
        store.$overlay
            .removeDuplicates()
            .sink { [weak self] kind in
                Task { @MainActor in self?.updateOverlay(kind) }
            }
            .store(in: &cancellables)
    }

    private func updateOverlay(_ kind: OverlayKind) {
        guard let overlayWindow else { return }
        if kind == .none {
            overlayWindow.orderOut(nil)
        } else {
            if let frame = NSScreen.main?.frame {
                overlayWindow.setFrame(frame, display: true)
            }
            NSApp.activate(ignoringOtherApps: true)
            overlayWindow.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: NSWindowDelegate

    func windowDidMove(_ notification: Notification) {
        guard (notification.object as? NSWindow) === widgetPanel else { return }
        // Re-pin the top edge so the widget keeps growing downward from where the
        // user dropped it. The position itself isn't persisted — launch always
        // re-centers — so there's nothing to save here.
        pinnedTop = widgetPanel.frame.maxY
    }

    func windowDidResize(_ notification: Notification) {
        guard (notification.object as? NSWindow) === widgetPanel, let top = pinnedTop else { return }
        var frame = widgetPanel.frame
        let newOriginY = top - frame.height
        if abs(frame.origin.y - newOriginY) > 0.5 {
            frame.origin.y = newOriginY
            widgetPanel.setFrame(frame, display: true)
        }
    }
}
