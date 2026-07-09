import SwiftUI

/// The frosted "Liquid Glass" surface used by the widget and the overlays:
/// vibrancy blur + material tint + hairline border + layered shadow.
/// Mirrors the prototype's card/pop CSS (`backdrop-filter` + `rgb(mat/a)` + `--shd`).
struct GlassCard: ViewModifier {
    let theme: Theme
    var radius: CGFloat = 14
    var tint: Color?
    /// Disable the SwiftUI shadow when the hosting NSWindow draws a native one.
    var shadow: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectBackground(
                        material: theme.vibrancyMaterial,
                        appearance: theme.vibrancyAppearance
                    )
                    (tint ?? theme.material)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(theme.line, lineWidth: 1)
            )
            .overlay( // inset top highlight (`inset 0 1px 0 rgba(255,255,255,...)`)
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(theme.isDark ? 0.09 : 0.6), .clear],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .mask {
                        LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)
                    }
            )
            .shadow(color: shadow ? theme.shadowColor : .clear, radius: shadow ? 30 : 0, x: 0, y: shadow ? 22 : 0)
            .shadow(color: shadow ? theme.shadowColor.opacity(0.6) : .clear, radius: shadow ? 5 : 0, x: 0, y: shadow ? 2 : 0)
    }
}

extension View {
    func glassCard(_ theme: Theme, radius: CGFloat = 14, tint: Color? = nil, shadow: Bool = true) -> some View {
        modifier(GlassCard(theme: theme, radius: radius, tint: tint, shadow: shadow))
    }
}
