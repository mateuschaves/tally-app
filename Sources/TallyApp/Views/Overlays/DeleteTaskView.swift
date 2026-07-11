import SwiftUI
import TallyCore

/// "Apagar tarefa?" confirmation card, ported from the prototype's `delOpen`
/// modal: trash badge, the task's title, a warning note and Cancelar/Apagar
/// (⏎ confirms, esc cancels — esc is handled by `OverlayRootView`).
struct DeleteTaskView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            TrashShape()
                .stroke(theme.red,
                        style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
                .frame(width: 17, height: 18)
                .frame(width: 42, height: 42)
                .background(Circle().fill(theme.red.opacity(0.14)))

            Text("Apagar tarefa?")
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 12)

            Text("“\(store.deleteTask?.title ?? "")”")
                .font(.system(size: 12.5))
                .foregroundColor(theme.tx2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .truncationMode(.tail)
                .lineSpacing(2)
                .padding(.top, 5)

            Text("Ela sai da fila e do resumo do dia. Essa ação não pode ser desfeita.")
                .font(.system(size: 11))
                .foregroundColor(theme.tx3)
                .multilineTextAlignment(.center)
                .lineSpacing(2.5)
                .padding(.top, 7)

            HStack(spacing: 8) {
                Button {
                    store.closeAll()
                } label: {
                    Text("Cancelar")
                        .font(.system(size: 12.5))
                        .foregroundColor(theme.tx1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(theme.selection)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    store.confirmDelete()
                } label: {
                    Text("Apagar")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(theme.blockRed)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction) // ⏎ confirma
            }
            .padding(.top, 15)

            Text("⏎ confirma · esc cancela")
                .font(.system(size: 10.5))
                .foregroundColor(theme.tx3)
                .padding(.top, 10)
        }
        .padding(EdgeInsets(top: 20, leading: 18, bottom: 13, trailing: 18))
        .frame(width: 296)
        .glassCard(theme, radius: 14, tint: theme.popover(0.96))
    }
}
