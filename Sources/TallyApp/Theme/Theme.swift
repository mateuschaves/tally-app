import SwiftUI
import AppKit

extension Color {
    /// Build a Color from `#RRGGBB` (the format used throughout the prototype).
    init(hex: String) {
        var string = hex
        if string.hasPrefix("#") { string.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: string).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

/// Design tokens for a given appearance, ported from the prototype's `:root`
/// and `[data-theme="light"]` blocks. This is the single source of truth for
/// every color/alpha in the UI, so the widget matches the mock exactly.
struct Theme: Equatable {
    enum Mode: String, Codable { case dark, light }

    let mode: Mode
    let accentHex: String
    /// 0…85, the prototype's transparency slider.
    let transparency: Double

    var isDark: Bool { mode == .dark }

    // MARK: Accent

    var accent: Color { Color(hex: accentHex) }

    // MARK: Material alpha (transparency slider)

    /// `matAlpha = min(0.97, max(0.06, 1 - trans/100))`.
    var materialAlpha: Double {
        min(0.97, max(0.06, 1 - transparency / 100))
    }

    // MARK: Text / lines / selection

    private func white(_ a: Double) -> Color { Color(.sRGB, red: 1, green: 1, blue: 1, opacity: a) }
    private func black(_ a: Double) -> Color { Color(.sRGB, red: 0, green: 0, blue: 0, opacity: a) }

    var tx1: Color { isDark ? white(0.96) : black(0.88) }
    var tx2: Color { isDark ? white(0.60) : black(0.55) }
    var tx3: Color { isDark ? white(0.36) : black(0.34) }
    var line: Color { isDark ? white(0.12) : black(0.10) }
    var selection: Color { isDark ? white(0.07) : black(0.055) }

    // MARK: Materials

    private var matRGB: (Double, Double, Double) { isDark ? (28, 28, 34) : (246, 246, 250) }
    private var popRGB: (Double, Double, Double) { isDark ? (44, 44, 52) : (252, 252, 255) }

    private func rgb(_ c: (Double, Double, Double), _ a: Double) -> Color {
        Color(.sRGB, red: c.0 / 255, green: c.1 / 255, blue: c.2 / 255, opacity: a)
    }

    /// Widget card tint: `rgb(var(--mat-rgb) / var(--a))`.
    var material: Color { rgb(matRGB, materialAlpha) }
    /// Material tint at an explicit alpha: `rgb(var(--mat-rgb) / a)`.
    func material(_ a: Double) -> Color { rgb(matRGB, a) }
    /// Popover/overlay tint at a given alpha: `rgb(var(--pop-rgb) / a)`.
    func popover(_ a: Double) -> Color { rgb(popRGB, a) }
    /// Pure-glass card tint (Variante Vidro puro uses `--a * 0.35`); kept for reuse.
    var glassMaterial: Color { rgb(matRGB, materialAlpha * 0.35) }

    // MARK: Fixed accents (state colors, same in both themes)

    let green = Color(hex: "#30D158")
    let red = Color(hex: "#FF453A")
    let blockRed = Color(hex: "#E5484D")

    /// Neutral progress-bar track (`rgba(128,128,128,0.16)`), theme-independent
    /// by design so a bar reads the same in light and dark.
    var barTrack: Color { Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 0.16) }

    // MARK: Shadow (approximation of --shd)

    var shadowColor: Color { isDark ? black(0.5) : black(0.2) }

    /// AppKit vibrancy material used behind the glass tint.
    var vibrancyMaterial: NSVisualEffectView.Material { .hudWindow }
    var vibrancyAppearance: NSAppearance? {
        NSAppearance(named: isDark ? .vibrantDark : .vibrantLight)
    }
}

// MARK: - Environment plumbing

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme(mode: .dark, accentHex: "#0A84FF", transparency: 40)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
