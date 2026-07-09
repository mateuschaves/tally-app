import SwiftUI
import AppKit

/// A transparent AppKit layer that drags its host window when clicked — used
/// behind the card header so the widget can be repositioned by its "grab" area,
/// like the prototype's `cursor: grab` header. More reliable than
/// `isMovableByWindowBackground` alone with SwiftUI-hosted content.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
