import SwiftUI
import TallyCore

/// "Marcar como impedida" dialog: reason text + quick reasons (mock lines 441–461).
struct BlockDialogView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme
    @FocusState private var focused: Bool

    private let reasons = [
        "Aguardando revisão",
        "Dependência de terceiros",
        "Sem acesso ou permissão",
        "Aguardando resposta"
    ]

    private var blockedTitle: String {
        guard let id = store.blockId else { return "" }
        return store.tasks.first { $0.id == id }?.title ?? ""
    }

    var body: some View {
        box
            .frame(width: 384)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var box: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Text("⚑")
                    .font(.system(size: 13))
                    .foregroundColor(theme.red)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(theme.red.opacity(0.15)))
                Text("Marcar como impedida")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.tx1)
            }

            Text(blockedTitle)
                .font(.system(size: 12.5))
                .foregroundColor(theme.tx2)
                .padding(.top, 9)
                .padding(.bottom, 11)

            reasonEditor

            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(reasons, id: \.self) { reason in
                    Button {
                        store.blockReason = reason
                    } label: {
                        Text(reason)
                            .font(.system(size: 11))
                            .foregroundColor(theme.tx2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 9)

            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button("Cancelar") { store.closeAll() }
                    .buttonStyle(SoftButtonStyle(theme: theme))
                Button("Impedir") { store.confirmBlock() }
                    .buttonStyle(BlockButtonStyle(theme: theme))
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.top, 15)
        }
        .padding(.horizontal, 17)
        .padding(.top, 17)
        .padding(.bottom, 15)
        .glassCard(theme, radius: 14, tint: theme.popover(0.95))
        .onAppear { focused = true }
    }

    private var reasonEditor: some View {
        TextEditor(text: Binding(get: { store.blockReason }, set: { store.blockReason = $0 }))
            .focused($focused)
            .font(.system(size: 13))
            .foregroundColor(theme.tx1)
            .scrollContentBackground(.hidden)
            .frame(height: 66)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(theme.selection))
            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
            .overlay(alignment: .topLeading) {
                if store.blockReason.isEmpty {
                    Text("Qual é o motivo do impedimento?")
                        .font(.system(size: 13))
                        .foregroundColor(theme.tx3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }
            }
    }
}

/// Destructive confirm button: `background: #E5484D`.
struct BlockButtonStyle: ButtonStyle {
    let theme: Theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(theme.blockRed.opacity(configuration.isPressed ? 0.85 : 1)))
    }
}
