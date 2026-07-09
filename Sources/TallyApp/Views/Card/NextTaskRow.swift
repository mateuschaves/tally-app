import SwiftUI
import TallyCore

/// A row in "A SEGUIR": start button, title, project dot, estimate, block flag.
/// Highlights on hover (`style-hover="background: var(--sel)"`).
struct NextTaskRow: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme
    let task: TaskItem
    @State private var hover = false

    var body: some View {
        HStack(spacing: 9) {
            StartButton(theme: theme, size: 15) { store.start(task.id) }

            Text(task.title)
                .font(.system(size: 12.5))
                .foregroundColor(theme.tx1)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Dot(color: store.color(for: task.project), size: 6)

            Text(TimeFormat.minutes(task.estimate))
                .font(.system(size: 10.5))
                .monospacedDigit()
                .foregroundColor(theme.tx3)

            FlagButton(theme: theme, baseOpacity: 0.25, fontSize: 11) { store.openBlock(task.id) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(hover ? theme.selection : .clear)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
    }
}
