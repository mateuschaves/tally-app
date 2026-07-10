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
