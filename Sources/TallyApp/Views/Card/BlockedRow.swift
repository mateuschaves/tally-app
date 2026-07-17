import SwiftUI
import TallyCore

/// A row in "IMPEDIDAS": red flag, title + italic reason, resume (↺).
struct BlockedRow: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme
    let task: TaskItem
    @State private var hover = false

    var body: some View {
        HStack(spacing: 9) {
            Text("⚑")
                .font(.system(size: 11))
                .foregroundColor(theme.red)

            VStack(alignment: .leading, spacing: 0) {
                Text(task.title)
                    .font(.system(size: 12.5))
                    .foregroundColor(theme.tx2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(task.reason ?? "")
                    .font(.system(size: 10.5))
                    .italic()
                    .foregroundColor(theme.tx3)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PencilButton(theme: theme, size: 22, glyphSize: 11, baseOpacity: 0.4) { store.openEdit(task.id) }
            UnblockButton(theme: theme) { store.unblock(task.id) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(hover ? theme.selection : .clear)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .help(task.reason ?? "")
    }
}
