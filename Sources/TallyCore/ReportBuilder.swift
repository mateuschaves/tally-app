import Foundation

/// Builds the "Resumo do dia" model + copyable text for a given day offset,
/// ported from the report section of the prototype's `renderVals`.
///
/// Colors are intentionally excluded — rows carry a `project` name and the UI
/// resolves the color, keeping this type free of AppKit/SwiftUI.
public enum ReportBuilder {

    public struct BarRow: Equatable, Sendable {
        public let title: String
        public let project: String
        public let label: String
        /// Width percentage 3…100.
        public let width: Int
    }

    public struct DoneLine: Equatable, Sendable {
        public let title: String
        public let secondsLabel: String
    }

    public struct BlockedLine: Equatable, Sendable {
        public let title: String
        public let reason: String
    }

    public struct PlanLine: Equatable, Sendable {
        public let title: String
        public let estimateLabel: String
    }

    public struct Report: Equatable, Sendable {
        /// The date this report is about (today, or the historical day).
        public let date: Date
        /// Long pt-BR label, e.g. "quinta-feira, 9 de julho".
        public let dateLabel: String
        /// Subheading, e.g. "Gerado às 14:32 · pronto para enviar ao gestor".
        public let subtitle: String
        public let isEmpty: Bool
        public let isToday: Bool

        public let doneCount: Int
        public let blockedCount: Int
        public let planCount: Int
        /// Total focus label, e.g. "3h 12m".
        public let focusLabel: String

        public let bars: [BarRow]
        public let doneTasks: [DoneLine]
        public let blockedTasks: [BlockedLine]
        public let planList: [PlanLine]

        /// Card label under the plan stat ("Para amanhã" / "Planejadas").
        public let planCardLabel: String
        /// Section title ("◻ PLANO DE AMANHÃ" / "◻ PLANEJADO PARA O DIA SEGUINTE").
        public let planTitle: String

        /// The active task title/label, only present for today ("▶ EM ANDAMENTO").
        public let currentTitle: String?
        public let currentSecondsLabel: String?

        /// The full plain-text summary ready to copy to the manager.
        public let text: String
    }

    /// Build the report for `offset` days ago (0 = today, from live `tasks`).
    /// Past days are derived from real completions — tasks whose `doneAt` falls on
    /// that day — so there is no synthetic/sample history.
    public static func build(
        tasks: [TaskItem],
        offset rawOffset: Int,
        now: Date
    ) -> Report {
        let offset = max(0, min(7, rawOffset))
        let isToday = offset == 0

        // Live-derived values (used for today, and for the "em andamento" line).
        let current = tasks.first { $0.state == .now }
        let nextTasks = tasks.filter { $0.state == .next }
        let blockedTasks = tasks.filter { $0.state == .blocked }
        let doneTasks = tasks.filter { $0.state == .done }
        let focusSeconds = tasks.reduce(0) { $0 + $1.seconds }

        let clockTime = PtBrDates.time(now)

        var displayDate = now
        var dateLabel = PtBrDates.long(now)
        var subtitle = "Gerado às \(clockTime) · pronto para enviar ao gestor"
        var isEmpty = false
        var planCardLabel = "Para amanhã"
        var planTitle = "◻ PLANO DE AMANHÃ"

        var rDone: [DoneLine]
        var rBlocked: [BlockedLine]
        var rPlan: [PlanLine]
        var rFocusSeconds: Int
        var rBars: [BarRow]

        if isToday {
            rDone = doneTasks.map { DoneLine(title: $0.title, secondsLabel: TimeFormat.duration($0.seconds)) }
            rBlocked = blockedTasks.map { BlockedLine(title: $0.title, reason: $0.reason ?? "") }
            rPlan = nextTasks.map { PlanLine(title: $0.title, estimateLabel: TimeFormat.minutes($0.estimate)) }
                + blockedTasks.map { PlanLine(title: $0.title + " (desbloquear)", estimateLabel: TimeFormat.minutes($0.estimate)) }
            rFocusSeconds = focusSeconds
            rBars = todayBars(from: tasks)
        } else {
            let target = dayDate(offset: offset, now: now)
            displayDate = target
            dateLabel = PtBrDates.long(target)
            planCardLabel = "Planejadas"
            planTitle = "◻ PLANEJADO PARA O DIA SEGUINTE"
            subtitle = "Histórico · " + (offset == 1 ? "ontem" : "\(offset) dias atrás")

            // Real history: tasks completed on that calendar day.
            let calendar = PtBrDates.calendar
            let doneThatDay = tasks.filter { task in
                guard task.state == .done, let doneAt = task.doneAt else { return false }
                return calendar.isDate(doneAt, inSameDayAs: target)
            }

            // Blocked/plan are ephemeral states with no per-day snapshot, so past
            // days only carry what was actually completed.
            rBlocked = []
            rPlan = []
            rDone = doneThatDay.map { DoneLine(title: $0.title, secondsLabel: TimeFormat.duration($0.seconds)) }
            rFocusSeconds = doneThatDay.reduce(0) { $0 + $1.seconds }
            let maxSeconds = max(1, doneThatDay.map { $0.seconds }.max() ?? 1)
            rBars = doneThatDay
                .sorted { $0.seconds > $1.seconds }
                .map { BarRow(title: $0.title, project: $0.project,
                              label: TimeFormat.duration($0.seconds),
                              width: barWidth($0.seconds, max: maxSeconds)) }

            if doneThatDay.isEmpty {
                isEmpty = true
            }
        }

        let text = buildText(
            dateLabel: dateLabel, isEmpty: isEmpty, isToday: isToday,
            focusSeconds: rFocusSeconds, done: rDone, blocked: rBlocked, plan: rPlan,
            current: current
        )

        return Report(
            date: displayDate, dateLabel: dateLabel, subtitle: subtitle,
            isEmpty: isEmpty, isToday: isToday,
            doneCount: rDone.count, blockedCount: rBlocked.count, planCount: rPlan.count,
            focusLabel: TimeFormat.duration(rFocusSeconds),
            bars: rBars, doneTasks: rDone, blockedTasks: rBlocked, planList: rPlan,
            planCardLabel: planCardLabel, planTitle: planTitle,
            currentTitle: isToday ? current?.title : nil,
            currentSecondsLabel: isToday ? current.map { TimeFormat.duration($0.seconds) } : nil,
            text: text
        )
    }

    // MARK: - Helpers

    /// Bars for today: tasks with > 30s, sorted desc, top 6 (ported from `withSec`).
    private static func todayBars(from tasks: [TaskItem]) -> [BarRow] {
        let withSeconds = tasks.filter { $0.seconds > 30 }.sorted { $0.seconds > $1.seconds }.prefix(6)
        let maxSeconds = withSeconds.first?.seconds ?? 1
        return withSeconds.map { task in
            BarRow(title: task.title, project: task.project,
                   label: TimeFormat.duration(task.seconds),
                   width: barWidth(task.seconds, max: maxSeconds))
        }
    }

    private static func barWidth(_ seconds: Int, max maxSeconds: Int) -> Int {
        max(3, Int((Double(seconds) / Double(maxSeconds) * 100).rounded()))
    }

    /// Noon on the day `offset` days before `now` — the bucket used to match
    /// completions by `doneAt`.
    private static func dayDate(offset: Int, now: Date) -> Date {
        let calendar = PtBrDates.calendar
        let comps = calendar.dateComponents([.year, .month, .day], from: now)
        let noon = calendar.date(from: DateComponents(
            year: comps.year, month: comps.month, day: comps.day, hour: 12)) ?? now
        return calendar.date(byAdding: .day, value: -offset, to: noon) ?? now
    }

    /// The copyable plain-text summary, ported from the `L.push(...)` block.
    private static func buildText(
        dateLabel: String, isEmpty: Bool, isToday: Bool,
        focusSeconds: Int, done: [DoneLine], blocked: [BlockedLine], plan: [PlanLine],
        current: TaskItem?
    ) -> String {
        var lines: [String] = []
        lines.append("Resumo do dia — \(dateLabel)")
        if isEmpty {
            lines.append("Sem atividade registrada.")
            return lines.joined(separator: "\n")
        }

        lines.append("Foco total: \(TimeFormat.duration(focusSeconds)) · \(done.count) concluída(s) · \(blocked.count) impedida(s)")
        lines.append("")
        lines.append("✔ Concluídas")
        for line in done { lines.append("• \(line.title) (\(line.secondsLabel))") }
        if done.isEmpty { lines.append("• —") }

        if isToday {
            lines.append("")
            lines.append("▶ Em andamento")
            if let current {
                lines.append("• \(current.title) (\(TimeFormat.duration(current.seconds)) de \(TimeFormat.minutes(current.estimate)))")
            } else {
                lines.append("• —")
            }
        }

        lines.append("")
        lines.append("⚑ Impedidas")
        for line in blocked { lines.append("• \(line.title) — \(line.reason)") }
        if blocked.isEmpty { lines.append("• —") }

        lines.append("")
        lines.append(isToday ? "Plano de amanhã" : "Planejado para o dia seguinte")
        for line in plan { lines.append("• \(line.title) (est. \(line.estimateLabel))") }
        if plan.isEmpty { lines.append("• —") }

        return lines.joined(separator: "\n")
    }
}
