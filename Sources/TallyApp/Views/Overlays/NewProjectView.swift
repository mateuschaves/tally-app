import SwiftUI

/// "Novo projeto" modal — name + color palette (mock lines 569–586).
struct NewProjectView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme
    @FocusState private var focused: Bool

    private let palette = ["#0A84FF", "#5AC8FA", "#30D158", "#FFD60A", "#FF9F0A", "#FF375F", "#BF5AF2", "#98989D"]

    var body: some View {
        box
            .frame(width: 320)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var box: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Novo projeto")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.tx1)
                .padding(.bottom, 12)

            TextField("Nome do projeto", text: Binding(get: { store.newProjectName }, set: { store.newProjectName = $0 }))
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(theme.tx1)
                .focused($focused)
                .onSubmit { store.confirmNewProject() }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.selection))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(theme.line, lineWidth: 1))

            Text("COR")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(theme.tx3)
                .padding(.top, 13)
                .padding(.bottom, 8)

            FlowLayout(spacing: 10, lineSpacing: 10) {
                ForEach(palette, id: \.self) { hex in
                    swatch(hex)
                }
            }

            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button("Cancelar") { store.closeNewProject() }
                    .buttonStyle(SoftButtonStyle(theme: theme))
                Button("Adicionar") { store.confirmNewProject() }
                    .buttonStyle(AccentButtonStyle(theme: theme))
            }
            .padding(.top, 17)
        }
        .padding(.horizontal, 17)
        .padding(.top, 16)
        .padding(.bottom, 15)
        .glassCard(theme, radius: 14, tint: theme.popover(0.96))
        .onAppear { focused = true }
    }

    private func swatch(_ hex: String) -> some View {
        let selected = store.newProjectColor.lowercased() == hex.lowercased()
        return Button {
            store.newProjectColor = hex
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .strokeBorder(theme.accent, lineWidth: 2)
                        .padding(-4)
                        .opacity(selected ? 1 : 0)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
