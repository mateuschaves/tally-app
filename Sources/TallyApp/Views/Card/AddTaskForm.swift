import SwiftUI
import TallyCore

/// The detailed "Nova tarefa" form (title, project, priority, estimate),
/// ported from the Cartão compacto form (lines 157–191 of the mock).
struct AddTaskForm: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme
    @FocusState private var titleFocused: Bool

    private let estimates = [60, 120, 240, 480, 960]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleField
            detailsField

            field(label: "PROJETO") {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(store.projects) { project in
                        projectPill(project)
                    }
                    newProjectPill
                }
            }

            field(label: "PRIORIDADE") {
                prioritySegment
            }

            field(label: "ESTIMATIVA") {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(estimates, id: \.self) { minutes in
                        estimatePill(minutes)
                    }
                }
            }

            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button("Cancelar") { store.closeAdd() }
                    .buttonStyle(SoftButtonStyle(theme: theme))
                Button("Adicionar") { store.submitForm() }
                    .buttonStyle(AccentButtonStyle(theme: theme))
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .onAppear { titleFocused = true }
    }

    // MARK: Pieces

    private var titleField: some View {
        TextField(
            "Título da tarefa",
            text: Binding(get: { store.form.title }, set: { store.form.title = $0 })
        )
        .textFieldStyle(.plain)
        .font(.system(size: 13))
        .foregroundColor(theme.tx1)
        .focused($titleFocused)
        .onSubmit { store.submitForm() }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.selection))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
    }

    private var detailsField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: Binding(get: { store.form.details }, set: { store.form.details = $0 }))
                .font(.system(size: 12.5))
                .foregroundColor(theme.tx1)
                .scrollContentBackground(.hidden)
                .frame(height: 44)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            if store.form.details.isEmpty {
                Text("Descrição (opcional)")
                    .font(.system(size: 12.5))
                    .foregroundColor(theme.tx3)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
        }
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.selection))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
    }

    private var newProjectPill: some View {
        Button {
            store.openNewProject()
        } label: {
            HStack(spacing: 4) {
                Text("+ Novo")
                    .font(.system(size: 11.5))
                    .foregroundColor(theme.tx2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(theme.line, style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
        }
        .buttonStyle(.plain)
        .help("Cadastrar novo projeto")
    }

    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(theme.tx3)
            content()
        }
    }

    private func projectPill(_ project: ProjectInfo) -> some View {
        let selected = store.form.project == project.name
        return Button {
            store.form.project = project.name
        } label: {
            HStack(spacing: 5) {
                Dot(color: Color(hex: project.colorHex), size: 6)
                Text(project.name)
                    .font(.system(size: 11.5))
                    .foregroundColor(theme.tx1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(selected ? theme.selection : .clear))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(selected ? theme.accent : theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var prioritySegment: some View {
        HStack(spacing: 0) {
            ForEach(Priority.allCases, id: \.self) { priority in
                let selected = store.form.priority == priority
                Button {
                    store.form.priority = priority
                } label: {
                    Text(priority.label)
                        .font(.system(size: 11.5, weight: selected ? .semibold : .regular))
                        .foregroundColor(theme.tx1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(selected ? theme.popover(0.9) : .clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(theme.selection))
    }

    private func estimatePill(_ minutes: Int) -> some View {
        let selected = store.form.estimate == minutes
        return Button {
            store.form.estimate = minutes
        } label: {
            Text(TimeFormat.minutes(minutes))
                .font(.system(size: 11.5))
                .monospacedDigit()
                .foregroundColor(theme.tx1)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(selected ? theme.selection : .clear))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? theme.accent : theme.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Button styles reused by forms/dialogs

/// Neutral button: `background: var(--sel)`.
struct SoftButtonStyle: ButtonStyle {
    let theme: Theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5))
            .foregroundColor(theme.tx1)
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(theme.selection.opacity(configuration.isPressed ? 0.6 : 1)))
    }
}

/// Primary button: `background: var(--acc)`.
struct AccentButtonStyle: ButtonStyle {
    let theme: Theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(theme.accent.opacity(configuration.isPressed ? 0.85 : 1)))
    }
}
