import SwiftUI
import TallyCore

/// "Resumo do dia" — stats, time-per-task bars, done/blocked/plan lists and the
/// copyable text, navigable across days (mock lines 464–567).
struct DayReportView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.theme) private var theme

    private var report: ReportBuilder.Report { store.report }
    private var isToday: Bool { store.reportOffset == 0 }
    private var atOldest: Bool { store.reportOffset >= 7 }

    /// Measured height of the scrollable content, so the card hugs its content
    /// (short reports stay short) instead of stretching to the full screen.
    @State private var contentHeight: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            // Cap the scroll area well below the full screen height so the card
            // opens compact; it scrolls when the content is longer.
            box(scrollCap: min(geo.size.height - 200, 420))
                .frame(width: 660)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func box(scrollCap: CGFloat) -> some View {
        VStack(spacing: 0) {
            titleBar
            ScrollView {
                content
                    .padding(.horizontal, 22)
                    .padding(.vertical, 20)
                    .background(GeometryReader { proxy in
                        Color.clear.preference(key: ReportContentHeightKey.self, value: proxy.size.height)
                    })
            }
            .frame(height: min(contentHeight, max(140, scrollCap)))
            footer
        }
        .onPreferenceChange(ReportContentHeightKey.self) { contentHeight = $0 }
        .glassCard(theme, radius: 15, tint: theme.popover(0.96))
        .overlay(navigationKeys)
    }

    // MARK: Title bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            Button(action: { store.closeAll() }) {
                Circle().fill(Color(hex: "#ff736a"))
                    .frame(width: 13, height: 13)
                    .overlay(Circle().strokeBorder(.black.opacity(0.15), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Fechar")

            Circle().fill(theme.selection).frame(width: 13, height: 13)
                .overlay(Circle().strokeBorder(theme.line, lineWidth: 0.5))
            Circle().fill(theme.selection).frame(width: 13, height: 13)
                .overlay(Circle().strokeBorder(theme.line, lineWidth: 0.5))

            Text("Resumo do dia")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.tx2)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 55)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) { Rectangle().fill(theme.line).frame(height: 1) }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        header
        if report.isEmpty {
            emptyState
        } else {
            statsGrid
            barsSection
            listsSection
            copyTextSection
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(report.dateLabel.capitalized(with: Locale(identifier: "pt_BR")))
                    .font(.system(size: 19, weight: .bold))
                    .tracking(-0.38)
                    .foregroundColor(theme.tx1)
                Text(report.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(theme.tx3)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                navButton("‹", disabled: atOldest) { store.reportPrev() }
                if !isToday {
                    Button("Hoje") { store.reportToday() }
                        .buttonStyle(NavPillStyle(theme: theme))
                }
                navButton("›", disabled: isToday) { store.reportNext() }
            }
        }
    }

    private func navButton(_ glyph: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: 15))
                .foregroundColor(theme.tx1)
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.selection))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
                .opacity(disabled ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Text("☾").font(.system(size: 24)).foregroundColor(theme.tx3)
            Text("Sem atividade registrada")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(theme.tx1)
                .padding(.top, 10)
            Text("Nenhuma tarefa concluída neste dia.")
                .font(.system(size: 12))
                .foregroundColor(theme.tx3)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 56)
        .padding(.bottom, 64)
    }

    // MARK: Stats

    private var statsGrid: some View {
        HStack(spacing: 9) {
            statCard("\(report.doneCount)", "Concluídas", color: theme.green)
            statCard(report.focusLabel, "Tempo focado", color: theme.tx1)
            statCard("\(report.blockedCount)", "Impedidas", color: theme.red)
            statCard("\(report.planCount)", report.planCardLabel, color: theme.tx1)
        }
        .padding(.top, 17)
    }

    private func statCard(_ value: String, _ label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 21, weight: .bold))
                .monospacedDigit()
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10.5))
                .foregroundColor(theme.tx3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(theme.selection))
    }

    // MARK: Bars

    private var barsSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("TEMPO POR TAREFA")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundColor(theme.tx3)
                .padding(.top, 19)
                .padding(.bottom, 2)

            ForEach(Array(report.bars.enumerated()), id: \.offset) { _, bar in
                HStack(spacing: 10) {
                    Text(bar.title)
                        .font(.system(size: 12))
                        .foregroundColor(theme.tx2)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: 190, alignment: .trailing)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(theme.selection)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(store.color(for: bar.project).opacity(0.85))
                                .frame(width: geo.size.width * CGFloat(bar.width) / 100)
                        }
                    }
                    .frame(height: 14)
                    Text(bar.label)
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(theme.tx3)
                        .frame(width: 52, alignment: .leading)
                }
            }
        }
    }

    // MARK: Lists (done / blocked / plan)

    private var listsSection: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 0) {
                columnTitle("✓ CONCLUÍDAS", color: theme.green)
                ForEach(Array(report.doneTasks.enumerated()), id: \.offset) { _, item in
                    leaderRow(title: item.title, trailing: item.secondsLabel, titleColor: theme.tx1)
                }
                if isToday {
                    columnTitle("▶ EM ANDAMENTO", color: theme.accent).padding(.top, 14)
                    if let title = report.currentTitle {
                        leaderRow(title: title, trailing: report.currentSecondsLabel ?? "", titleColor: theme.tx1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                columnTitle("⚑ IMPEDIDAS", color: theme.red)
                ForEach(Array(report.blockedTasks.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title).font(.system(size: 12.5)).foregroundColor(theme.tx1)
                        Text(item.reason).font(.system(size: 11)).italic().foregroundColor(theme.tx3)
                    }
                    .padding(.vertical, 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                columnTitle(report.planTitle, color: theme.tx3).padding(.top, 14)
                ForEach(Array(report.planList.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Text(item.title).font(.system(size: 12.5)).foregroundColor(theme.tx2)
                        Spacer(minLength: 0)
                        Text(item.estimateLabel).font(.system(size: 11)).monospacedDigit().foregroundColor(theme.tx3)
                    }
                    .padding(.vertical, 3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 19)
    }

    private func columnTitle(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.9)
            .foregroundColor(color)
            .padding(.bottom, 8)
    }

    private func leaderRow(title: String, trailing: String, titleColor: Color) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 12.5)).foregroundColor(titleColor).lineLimit(1)
            DottedLeader(color: theme.line)
            Text(trailing).font(.system(size: 11)).monospacedDigit().foregroundColor(theme.tx3)
        }
        .padding(.vertical, 3)
    }

    // MARK: Copy text

    private var copyTextSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TEXTO PARA ENVIAR")
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.9)
                .foregroundColor(theme.tx3)
                .padding(.top, 19)
                .padding(.bottom, 8)
            Text(report.text)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundColor(theme.tx2)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(theme.selection))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
                .textSelection(.enabled)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Text("← → navegam entre os dias")
                .font(.system(size: 11))
                .foregroundColor(theme.tx3)
            Spacer(minLength: 0)
            Button("Fechar") { store.closeAll() }
                .buttonStyle(SoftButtonStyle(theme: theme))
            Button(store.copied ? "Copiado ✓" : "Copiar texto") { store.copyReport() }
                .buttonStyle(AccentButtonStyle(theme: theme))
                .frame(minWidth: 108)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .top) { Rectangle().fill(theme.line).frame(height: 1) }
    }

    // MARK: Keyboard

    private var navigationKeys: some View {
        ZStack {
            Button("") { store.reportPrev() }
                .keyboardShortcut(.leftArrow, modifiers: [])
            Button("") { store.reportNext() }
                .keyboardShortcut(.rightArrow, modifiers: [])
        }
        .buttonStyle(.plain)
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }
}

/// Carries the measured height of the report's scrollable content up to the box.
private struct ReportContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Small "Hoje" pill in the report header.
struct NavPillStyle: ButtonStyle {
    let theme: Theme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundColor(theme.tx1)
            .padding(.horizontal, 10)
            .frame(height: 26)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.selection))
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(theme.line, lineWidth: 1))
    }
}
