import SwiftUI
import AppKit
import TallyCore

/// The "Cartão compacto" widget — full recreation of the prototype's Variante 1.
struct CompactCardView: View {
    @EnvironmentObject private var store: AppStore

    private var theme: Theme { store.theme }

    private var currentTimer: String {
        store.current.map { TimeFormat.clock($0.seconds) } ?? "--:--"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if let current = store.current {
                CurrentTaskView(task: current)
            } else {
                emptyNow
            }

            hairline
            nextSection

            if store.hasBlocked {
                hairline
                blockedSection
            }

            hairline
            if store.addOpen {
                AddTaskForm()
            } else {
                QuickAddBar()
            }
        }
        .frame(width: 312)
        .foregroundColor(theme.tx1)
        .glassCard(theme, radius: 14, shadow: false)
        .environment(\.theme, theme)
        .animation(.easeOut(duration: 0.2), value: store.addOpen)
        .animation(.easeOut(duration: 0.2), value: store.hasBlocked)
        // Right-click to close/hide the widget (no visual change to the card).
        .contextMenu {
            Button("Nova tarefa") { store.openQuickEntry() }
            Button("Resumo do dia") { store.openReport() }
            Divider()
            Button("Ocultar widget") { store.onHideWidget?() }
            Divider()
            Button("Sair do Tally") { NSApplication.shared.terminate(nil) }
        }
    }

    // MARK: Header (drag handle)

    private var header: some View {
        HStack(spacing: 7) {
            PulseDot(color: theme.accent, size: 6)
            SectionLabel(text: "AGORA", color: theme.tx3)
            Spacer(minLength: 0)
            Text(currentTimer)
                .font(.system(size: 12.5))
                .monospacedDigit()
                .foregroundColor(theme.tx2)
            PauseButton(theme: theme, paused: store.paused) { store.togglePause() }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(WindowDragHandle())
        .environment(\.theme, theme)
    }

    private var emptyNow: some View {
        Text("Nada em andamento — adicione uma tarefa abaixo ou use ⌘K.")
            .font(.system(size: 12.5))
            .foregroundColor(theme.tx3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 14)
    }

    // MARK: A SEGUIR

    private var nextSection: some View {
        VStack(spacing: 0) {
            HStack {
                SectionLabel(text: "A SEGUIR", color: theme.tx3)
                Spacer(minLength: 0)
                Text(store.remainLabel)
                    .font(.system(size: 10.5))
                    .monospacedDigit()
                    .foregroundColor(theme.tx3)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 4)

            if store.noNext {
                Text("Fila vazia — bom sinal.")
                    .font(.system(size: 12))
                    .foregroundColor(theme.tx3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
            } else {
                ForEach(store.nextTasks) { task in
                    NextTaskRow(task: task)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .environment(\.theme, theme)
    }

    // MARK: IMPEDIDAS

    private var blockedSection: some View {
        VStack(spacing: 0) {
            SectionLabel(text: "IMPEDIDAS", color: theme.red)
                .opacity(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)

            ForEach(store.blockedTasks) { task in
                BlockedRow(task: task)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .environment(\.theme, theme)
    }

    private var hairline: some View {
        Rectangle().fill(theme.line).frame(height: 1)
    }
}
