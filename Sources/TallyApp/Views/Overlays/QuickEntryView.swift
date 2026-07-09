import SwiftUI
import TallyCore

/// The ⌘K Spotlight-style quick entry with the natural-language parser and
/// live preview chips (mock lines 415–437).
struct QuickEntryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme
    @FocusState private var focused: Bool

    private var chips: [String] {
        let parsed = QuickParse.parse(store.quickEntryText)
        var result: [String] = []
        if let project = parsed.project { result.append("Projeto: " + store.canonicalProjectPreview(project)) }
        if let priority = parsed.priority { result.append("Prioridade: " + priority.label) }
        if let estimate = parsed.estimate { result.append("Estimativa: " + TimeFormat.minutes(estimate)) }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                box
                    .frame(width: 560)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, geo.size.height * 0.17)
        }
    }

    private var box: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Text("+")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 27, height: 27)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.accent))

                TextField(
                    "Nova tarefa…",
                    text: Binding(get: { store.quickEntryText }, set: { store.quickEntryText = $0 })
                )
                .textFieldStyle(.plain)
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(theme.tx1)
                .focused($focused)
                .onSubmit { store.submitQuickEntry() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if !chips.isEmpty {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(chips, id: \.self) { chip in
                        Text(chip)
                            .font(.system(size: 11))
                            .foregroundColor(theme.tx2)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(theme.selection))
                            .overlay(Capsule().strokeBorder(theme.line, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 11)
            }

            hintFooter
        }
        .glassCard(theme, radius: 16, tint: theme.popover(0.94))
        .onAppear { focused = true }
    }

    private var hintFooter: some View {
        HStack(spacing: 14) {
            hint("#", "projeto")
            hint("!", "alta · !média · !baixa")
            hint("30m", " / 2h estimativa")
            Spacer(minLength: 0)
            Text("⏎ adiciona · esc fecha")
        }
        .font(.system(size: 11))
        .foregroundColor(theme.tx3)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .overlay(alignment: .top) { Rectangle().fill(theme.line).frame(height: 1) }
    }

    private func hint(_ bold: String, _ rest: String) -> some View {
        (Text(bold).foregroundColor(theme.tx2).bold() + Text(rest))
    }
}
