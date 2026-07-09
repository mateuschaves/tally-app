import SwiftUI

/// The bottom bar shown when the detailed form is closed: "+" to open the form,
/// a quick-add field, the done counter and the report button.
struct QuickAddBar: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 7) {
            AddPlusButton(theme: theme) { store.openAdd() }

            TextField(
                "Adicionar rápido… (⌘K)",
                text: Binding(get: { store.quick }, set: { store.quick = $0 })
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12.5))
            .foregroundColor(theme.tx1)
            .onSubmit { store.submitQuick() }

            Text("✓ \(store.doneCount)")
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundColor(theme.tx3)

            ReportButton(theme: theme) { store.openReport() }
        }
        .padding(.horizontal, 10)
        .padding(.top, 7)
        .padding(.bottom, 8)
    }
}
