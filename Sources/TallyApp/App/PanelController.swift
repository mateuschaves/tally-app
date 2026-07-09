import AppKit
import SwiftUI
import Combine

/// Owns the two AppKit windows — the floating widget and the shared full-screen
/// overlay — and keeps the overlay's visibility in sync with `store.overlay`.
/// Also pins the widget's top edge so it grows downward (like the mock, anchored
/// top-right) and persists its position after a drag.
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
        panel.orderFrontRegardless()
    }

    private func positionWidget() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = widgetPanel.frame.size
        let origin: CGPoint
        if let saved = store.widgetPosition {
            origin = saved
        } else {
            origin = CGPoint(x: visible.maxX - size.width - 36,
                             y: visible.maxY - size.height - 12)
        }
        widgetPanel.setFrameOrigin(origin)
        pinnedTop = widgetPanel.frame.maxY
    }

    func showWidget() { widgetPanel.orderFrontRegardless() }

    func toggleWidget() {
        if widgetPanel.isVisible {
            widgetPanel.orderOut(nil)
        } else {
            widgetPanel.orderFrontRegardless()
        }
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
        store.saveWidgetPosition(widgetPanel.frame.origin)
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
