import SwiftUI
import TallyCore

/// The "AGORA" task body: complete button, title, project/priority/estimate meta,
/// block flag and the progress bar. (Cartão compacto, lines 95–116 of the mock.)
struct CurrentTaskView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme
    let task: TaskItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            CompleteButton(theme: theme, size: 17) { store.complete(task.id) }
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 0) {
                Text(task.title)
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(-0.14)
                    .foregroundColor(theme.tx1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !task.details.isEmpty {
                    Text(task.details)
                        .font(.system(size: 11.5))
                        .foregroundColor(theme.tx2)
                        .lineSpacing(1.5)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                HStack(spacing: 9) {
                    HStack(spacing: 5) {
                        Dot(color: store.color(for: task.project), size: 7)
                        Text(task.project)
                            .font(.system(size: 11))
                            .foregroundColor(theme.tx2)
                    }
                    HStack(spacing: 4) {
                        Dot(color: Color(hex: task.priority.colorHex), size: 6)
                        Text(task.priority.label)
                            .font(.system(size: 11))
                            .foregroundColor(theme.tx2)
                    }
                    Text("est. \(TimeFormat.minutes(task.estimate))")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(theme.tx3)

                    Spacer(minLength: 0)

                    PencilButton(theme: theme, size: 24, glyphSize: 12, baseOpacity: 0.55) { store.openEdit(task.id) }
                    FlagButton(theme: theme, size: 24, glyphSize: 13, baseOpacity: 0.55) { store.openBlock(task.id) }
                }
                .padding(.top, 6)

                ProgressBar(percent: task.progressPercent, fill: theme.accent, track: theme.selection, height: 3)
                    .padding(.top, 9)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }
}
