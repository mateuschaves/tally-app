import SwiftUI

/// Circular "complete task" button. Empty ring by default; on hover it fills
/// green and reveals the check (`color: transparent` → green on hover).
struct CompleteButton: View {
    let theme: Theme
    var size: CGFloat = 22
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(hover ? theme.green.opacity(0.14) : .clear)
                Circle().strokeBorder(hover ? theme.green : theme.tx3, lineWidth: 1.5)
                CheckShape()
                    .stroke(hover ? theme.green : .clear,
                            style: StrokeStyle(lineWidth: max(1.6, size * 0.10), lineCap: .round, lineJoin: .round))
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

/// Small "start now" ring. On hover the ring turns accent and gains a soft halo
/// (`box-shadow: 0 0 0 3px rgba(accent, .2)`).
struct StartButton: View {
    let theme: Theme
    var size: CGFloat = 15
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Circle()
                .strokeBorder(hover ? theme.accent : theme.tx3, lineWidth: 1.5)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(theme.accent.opacity(hover ? 0.2 : 0))
                        .frame(width: size + 6, height: size + 6)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Começar agora")
    }
}

/// The "⚑ block" affordance. Dim by default, red on hover.
struct FlagButton: View {
    let theme: Theme
    var baseOpacity: Double = 0.4
    var fontSize: CGFloat = 12
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text("⚑")
                .font(.system(size: fontSize))
                .foregroundColor(hover ? theme.red : theme.tx2)
                .opacity(hover ? 1 : baseOpacity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Marcar como impedida")
    }
}

/// The "↺ resume" affordance for blocked tasks.
struct UnblockButton: View {
    let theme: Theme
    var fontSize: CGFloat = 13
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text("↺")
                .font(.system(size: fontSize))
                .foregroundColor(hover ? theme.accent : theme.tx3)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help("Retomar tarefa")
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
