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
    /// "TEXTO PARA ENVIAR" starts collapsed.
    @State private var reportTextOpen = false

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
            VStack(alignment: .leading, spacing: 10) {
                doneCard
                if isToday, report.currentTitle != nil {
                    inProgressCard
                }
                if !report.blockedTasks.isEmpty {
                    blockedCard
                }
                if !report.planList.isEmpty {
                    planCard
                }
                textCard
            }
            .padding(.top, 14)
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

    // MARK: Report cards

    private func reportCard<Content: View>(bottom: CGFloat = 5, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(.horizontal, 14)
            .padding(.top, 11)
            .padding(.bottom, bottom)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.selection))
    }

    private var cardHairline: some View { Rectangle().fill(theme.line).frame(height: 1) }

    private func cardLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold))
            .tracking(0.8)
            .foregroundColor(theme.tx2)
    }

    private func rowDetails(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(theme.tx3)
            .lineSpacing(1.5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
    }

    private var doneCard: some View {
        reportCard {
            HStack(spacing: 7) {
                Text("✓").font(.system(size: 12)).foregroundColor(theme.green)
                cardLabel("CONCLUÍDAS")
                Spacer(minLength: 0)
                Text("barra = tempo dedicado").font(.system(size: 10.5)).foregroundColor(theme.tx3)
            }
            .padding(.bottom, 7)

            if report.doneTasks.isEmpty {
                cardHairline
                Text("Nenhuma tarefa concluída neste dia.")
                    .font(.system(size: 12))
                    .foregroundColor(theme.tx3)
                    .padding(.top, 8)
                    .padding(.bottom, 5)
            } else {
                ForEach(Array(report.doneTasks.enumerated()), id: \.offset) { _, item in
                    doneRow(item)
                }
            }
        }
    }

    private func doneRow(_ item: ReportBuilder.DoneLine) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHairline
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(item.title)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(theme.tx1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(item.secondsLabel)
                        .font(.system(size: 11)).monospacedDigit().foregroundColor(theme.tx3)
                }
                if !item.details.isEmpty { rowDetails(item.details) }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(theme.barTrack)
                        Capsule().fill(store.color(for: item.project).opacity(0.9))
                            .frame(width: geo.size.width * CGFloat(item.width) / 100)
                    }
                }
                .frame(height: 3)
                .padding(.top, 7)
            }
            .padding(.vertical, 8)
        }
    }

    private var inProgressCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                PulseDot(color: theme.accent, size: 6)
                cardLabel("EM ANDAMENTO")
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(report.currentTitle ?? "")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(theme.tx1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(report.currentSecondsLabel ?? "") de \(report.currentEstimateLabel ?? "")")
                    .font(.system(size: 11)).monospacedDigit().foregroundColor(theme.tx3)
            }
            .padding(.top, 8)
            if let details = report.currentDetails, !details.isEmpty { rowDetails(details) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.selection))
    }

    private var blockedCard: some View {
        reportCard {
            HStack(spacing: 7) {
                Text("⚑").font(.system(size: 12)).foregroundColor(theme.red)
                cardLabel("IMPEDIDAS")
            }
            .padding(.bottom, 7)
            ForEach(Array(report.blockedTasks.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 0) {
                    cardHairline
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.title)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(theme.tx1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !item.details.isEmpty { rowDetails(item.details) }
                        (Text("motivo: ").foregroundColor(theme.red)
                            + Text(item.reason).foregroundColor(theme.tx2).italic())
                            .font(.system(size: 11))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var planCard: some View {
        reportCard {
            HStack(spacing: 7) {
                Text("◻").font(.system(size: 11)).foregroundColor(theme.tx3)
                cardLabel(report.planTitle)
            }
            .padding(.bottom, 7)
            ForEach(Array(report.planList.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 0) {
                    cardHairline
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(item.title).font(.system(size: 12.5)).foregroundColor(theme.tx2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("est. \(item.estimateLabel)")
                                .font(.system(size: 11)).monospacedDigit().foregroundColor(theme.tx3)
                        }
                        if !item.details.isEmpty { rowDetails(item.details) }
                    }
                    .padding(.vertical, 7)
                }
            }
        }
    }

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) { reportTextOpen.toggle() }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 11)).foregroundColor(theme.tx3)
                    cardLabel("TEXTO PARA ENVIAR")
                    Spacer(minLength: 0)
                    Text(reportTextOpen ? "ocultar" : "mostrar")
                        .font(.system(size: 11)).foregroundColor(theme.tx3)
                    Text("▾").font(.system(size: 9)).foregroundColor(theme.tx3)
                        .rotationEffect(.degrees(reportTextOpen ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if reportTextOpen {
                cardHairline
                Text(report.text)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(theme.tx2)
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.selection))
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
