import AppKit

/// Full-screen, transparent panel that hosts the modal overlays (⌘K quick entry,
/// block dialog, day report). It dims the screen and centers the box, matching
/// the prototype's `position: fixed; inset: 0` overlays. Becomes key so the
/// text fields work and Esc/arrow keys are captured.
final class OverlayWindow: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level = .modalPanel
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        animationBehavior = .none
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
