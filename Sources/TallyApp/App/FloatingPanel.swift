import AppKit

/// Borderless, always-on-top, non-activating panel that hosts the widget.
/// Joins every Space, is draggable by its background, and (unlike a plain
/// borderless `NSWindow`) can become key so the quick-add field accepts input.
final class FloatingPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true                 // native rounded-card shadow
        becomesKeyOnlyIfNeeded = true     // don't steal key focus on stray clicks
        animationBehavior = .utilityWindow
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
