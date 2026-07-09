import SwiftUI
import AppKit

/// Bridges `NSVisualEffectView` (behind-window blur) into SwiftUI — this is the
/// real macOS vibrancy under the glass tint, standing in for the prototype's
/// CSS `backdrop-filter: blur(...) saturate(...)`.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var appearance: NSAppearance?
    var isEmphasized: Bool = true

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = isEmphasized
        view.appearance = appearance
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.appearance = appearance
        view.isEmphasized = isEmphasized
    }
}
