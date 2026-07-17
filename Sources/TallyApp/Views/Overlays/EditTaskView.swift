import SwiftUI
import TallyCore

/// "Editar tarefa" overlay — adjusts a task's project, priority, estimate and
/// logged time (the four editable fields). Modeled on the "Novo projeto" modal:
/// a centered glass card with the same pill/segment controls as the add form,
/// plus hours+minutes steppers for the two durations. ⏎ saves, esc cancels
/// (esc is handled by `OverlayRootView`).
struct EditTaskView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme

    var body: some View {
        box
            .frame(width: 340)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var box: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Editar tarefa")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.tx1)

            if let title = store.editTask?.title {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(theme.tx2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 3)
            }

            field(label: "PROJETO") {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(store.projects) { project in
                        projectPill(project)
                    }
                }
            }
            .padding(.top, 15)

            field(label: "PRIORIDADE") {
                prioritySegment
            }
            .padding(.top, 12)

            field(label: "ESTIMATIVA") {
                DurationStepper(theme: theme, hours: estimateHours, minutes: estimateMinutes)
            }
            .padding(.top, 12)

            field(label: "REGISTRADO") {
                DurationStepper(theme: theme, hours: loggedHours, minutes: loggedMinutes)
            }
            .padding(.top, 12)

            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Button("Cancelar") { store.closeAll() }
                    .buttonStyle(SoftButtonStyle(theme: theme))
                Button("Salvar") { store.submitEdit() }
                    .buttonStyle(AccentButtonStyle(theme: theme))
                    .keyboardShortcut(.defaultAction) // ⏎ salva
            }
            .padding(.top, 17)

            Text("⏎ salva · esc cancela")
                .font(.system(size: 10.5))
                .foregroundColor(theme.tx3)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
        }
        .padding(.horizontal, 17)
        .padding(.top, 16)
        .padding(.bottom, 15)
        .glassCard(theme, radius: 14, tint: theme.popover(0.96))
    }

    // MARK: Derived bindings (hours/minutes ⇄ the stored minute/second totals)

    // The setters clamp the computed total to zero so the form state never goes
    // negative while typing — a stray negative entry would otherwise make the
    // `% 60`/`% 3600` remainders yield confusing hour/minute values.
    private var estimateHours: Binding<Int> {
        Binding(
            get: { store.editForm.estimate / 60 },
            set: { store.editForm.estimate = max(0, $0 * 60 + store.editForm.estimate % 60) }
        )
    }
    private var estimateMinutes: Binding<Int> {
        Binding(
            get: { store.editForm.estimate % 60 },
            set: { store.editForm.estimate = max(0, (store.editForm.estimate / 60) * 60 + $0) }
        )
    }
    private var loggedHours: Binding<Int> {
        Binding(
            get: { store.editForm.loggedSeconds / 3600 },
            set: { store.editForm.loggedSeconds = max(0, $0 * 3600 + store.editForm.loggedSeconds % 3600) }
        )
    }
    private var loggedMinutes: Binding<Int> {
        // Preserve the sub-minute remainder so editing minutes doesn't drop seconds.
        Binding(
            get: { (store.editForm.loggedSeconds % 3600) / 60 },
            set: {
                let leftoverSeconds = store.editForm.loggedSeconds % 60
                let hoursPart = (store.editForm.loggedSeconds / 3600) * 3600
                store.editForm.loggedSeconds = max(0, hoursPart + $0 * 60 + leftoverSeconds)
            }
        )
    }

    // MARK: Pieces (mirrors AddTaskForm, bound to `editForm`)

    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(theme.tx3)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func projectPill(_ project: ProjectInfo) -> some View {
        let selected = store.editForm.project == project.name
        return Button {
            store.editForm.project = project.name
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
                let selected = store.editForm.priority == priority
                Button {
                    store.editForm.priority = priority
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
}
