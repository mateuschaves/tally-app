import SwiftUI

/// Circular "complete task" button (17px). Empty ring by default; on hover it
/// fills green and reveals the check (`color: transparent` → green on hover).
struct CompleteButton: View {
    let theme: Theme
    var size: CGFloat = 17
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(hover ? theme.green.opacity(0.14) : .clear)
                Circle().strokeBorder(hover ? theme.green : theme.tx3, lineWidth: 1.3)
                CheckShape()
                    .stroke(hover ? theme.green : .clear,
                            style: StrokeStyle(lineWidth: max(1.5, size * 0.10), lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.5, height: size * 0.5)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Concluir tarefa")
    }
}

/// Small "start now" ring (17px). Empty by default; on hover the ring turns
/// accent and reveals a play triangle over a soft accent fill.
struct StartButton: View {
    let theme: Theme
    var size: CGFloat = 17
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(hover ? theme.accent.opacity(0.16) : .clear)
                Circle().strokeBorder(hover ? theme.accent : theme.tx3, lineWidth: 1.3)
                PlayTriangle()
                    .fill(hover ? theme.accent : .clear)
                    .frame(width: size * 0.42, height: size * 0.42)
                    .offset(x: size * 0.03)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Começar agora")
    }
}

/// The circular "⚑ block" affordance. Dim by default, red (with a soft red fill)
/// on hover.
struct FlagButton: View {
    let theme: Theme
    var size: CGFloat = 22
    var glyphSize: CGFloat = 12
    var baseOpacity: Double = 0.4
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text("⚑")
                .font(.system(size: glyphSize))
                .foregroundColor(hover ? theme.red : theme.tx2)
                .opacity(hover ? 1 : baseOpacity)
                .frame(width: size, height: size)
                .background(Circle().fill(hover ? theme.red.opacity(0.12) : .clear))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Marcar como impedida")
    }
}

/// The trash-can outline used by the delete affordances (viewBox 12×13 in the
/// prototype: lid, handle, body and two inner lines).
struct TrashShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width / 12
        let h = rect.height / 13
        var p = Path()
        // Lid.
        p.move(to: CGPoint(x: 1.2 * w, y: 3.4 * h))
        p.addLine(to: CGPoint(x: 10.8 * w, y: 3.4 * h))
        // Handle.
        p.move(to: CGPoint(x: 4.4 * w, y: 1.6 * h))
        p.addLine(to: CGPoint(x: 7.6 * w, y: 1.6 * h))
        // Body.
        p.move(to: CGPoint(x: 2.4 * w, y: 3.4 * h))
        p.addLine(to: CGPoint(x: 2.9 * w, y: 10.8 * h))
        p.addQuadCurve(to: CGPoint(x: 4.07 * w, y: 11.9 * h),
                       control: CGPoint(x: 3.0 * w, y: 11.9 * h))
        p.addLine(to: CGPoint(x: 7.93 * w, y: 11.9 * h))
        p.addQuadCurve(to: CGPoint(x: 9.1 * w, y: 10.8 * h),
                       control: CGPoint(x: 9.0 * w, y: 11.9 * h))
        p.addLine(to: CGPoint(x: 9.6 * w, y: 3.4 * h))
        // Inner lines.
        p.move(to: CGPoint(x: 4.7 * w, y: 5.6 * h))
        p.addLine(to: CGPoint(x: 4.7 * w, y: 9.2 * h))
        p.move(to: CGPoint(x: 7.3 * w, y: 5.6 * h))
        p.addLine(to: CGPoint(x: 7.3 * w, y: 9.2 * h))
        return p
    }
}

/// The circular trash affordance on queue rows. Dim by default, red (with a
/// soft red fill) on hover — same treatment as `FlagButton`.
struct TrashButton: View {
    let theme: Theme
    var size: CGFloat = 22
    var glyphSize: CGFloat = 11
    var baseOpacity: Double = 0.4
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            TrashShape()
                .stroke(hover ? theme.red : theme.tx2,
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                .opacity(hover ? 1 : baseOpacity)
                .frame(width: glyphSize, height: glyphSize + 1)
                .frame(width: size, height: size)
                .background(Circle().fill(hover ? theme.red.opacity(0.1) : .clear))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Apagar tarefa")
    }
}

/// The circular "↺ resume" affordance for blocked tasks (24px).
struct UnblockButton: View {
    let theme: Theme
    var size: CGFloat = 24
    var glyphSize: CGFloat = 14
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text("↺")
                .font(.system(size: glyphSize))
                .foregroundColor(hover ? theme.accent : theme.tx3)
                .frame(width: size, height: size)
                .background(Circle().fill(hover ? theme.selection : .clear))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Retomar tarefa")
    }
}

/// The macOS-style traffic-light close button (11px red) that hides the widget.
/// The "×" appears on hover.
struct WidgetCloseButton: View {
    let theme: Theme
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color(hex: "#ff736a"))
                CloseXShape()
                    .stroke(hover ? Color.black.opacity(0.45) : .clear,
                            style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    .frame(width: 6, height: 6)
            }
            .frame(width: 11, height: 11)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.2), lineWidth: 0.5))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Fechar")
    }
}

/// A decorative (inert) traffic-light dot next to the close button.
struct TrafficDot: View {
    let theme: Theme
    var body: some View {
        Circle()
            .fill(theme.selection)
            .frame(width: 11, height: 11)
            .overlay(Circle().strokeBorder(theme.line, lineWidth: 0.5))
    }
}

/// Pause/resume the running timer (glyph `❙❙` / `▶`).
struct PauseButton: View {
    let theme: Theme
    let paused: Bool
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text(paused ? "▶" : "❙❙")
                .font(.system(size: 10))
                .tracking(0.5)
                .foregroundColor(hover ? theme.tx1 : theme.tx3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Pausar / retomar cronômetro")
    }
}

/// The rounded "+" that opens the detailed add form.
struct AddPlusButton: View {
    let theme: Theme
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text("+")
                .font(.system(size: 14))
                .foregroundColor(hover ? .white : theme.accent)
                .frame(width: 20, height: 20)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hover ? theme.accent : theme.selection))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Nova tarefa detalhada")
    }
}

/// The small "day report" icon button (ruled document).
struct ReportButton: View {
    let theme: Theme
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 12))
                .foregroundColor(hover ? theme.accent : theme.tx2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Resumo do dia")
    }
}
