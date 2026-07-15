import Foundation

/// Builds the "Resumo do dia" model + copyable text for a given day offset,
/// ported from the report section of the prototype's `renderVals`.
///
/// Colors are intentionally excluded — rows carry a `project` name and the UI
/// resolves the color, keeping this type free of AppKit/SwiftUI.
public enum ReportBuilder {

    public struct DoneLine: Equatable, Sendable {
        public let title: String
        public let secondsLabel: String
        /// Project name (UI resolves the bar color).
        public let project: String
        /// Bar width percentage (2…100), relative to the longest task that day.
        public let width: Int
        /// The task's description (empty when none).
        public let details: String
    }

    public struct BlockedLine: Equatable, Sendable {
        public let title: String
        public let reason: String
        public let details: String
    }

    public struct PlanLine: Equatable, Sendable {
        public let title: String
        public let estimateLabel: String
        public let details: String
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

        public let doneTasks: [DoneLine]
        public let blockedTasks: [BlockedLine]
        public let planList: [PlanLine]

        /// Card label under the plan stat ("Para amanhã" / "Planejadas").
        public let planCardLabel: String
        /// Section title ("PLANO DE AMANHÃ" / "PLANEJADO PARA O DIA SEGUINTE").
        public let planTitle: String

        /// Fields of the active task (title/seconds/estimate/details), present only
        /// for today — these populate the "EM ANDAMENTO" card. `nil` on past days.
        public let currentTitle: String?
        public let currentSecondsLabel: String?
        public let currentEstimateLabel: String?
        public let currentDetails: String?

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

        // Completions belong to the calendar day they were finished on. This
        // helper filters `.done` tasks to a given day so a task finished on one
        // day never leaks into another day's summary — it stays in the store to
        // feed *its* day's history, but only surfaces there.
        let calendar = PtBrDates.calendar
        func doneTasks(on target: Date) -> [TaskItem] {
            tasks.filter { task in
                guard task.state == .done, let doneAt = task.doneAt else { return false }
                return calendar.isDate(doneAt, inSameDayAs: target)
            }
        }

        let clockTime = PtBrDates.time(now)

        var displayDate = now
        var dateLabel = PtBrDates.long(now)
        var subtitle = "Gerado às \(clockTime) · pronto para enviar ao gestor"
        var isEmpty = false
        var planCardLabel = "Para amanhã"
        var planTitle = "PLANO DE AMANHÃ"

        // The tasks that were completed this report's day (drives the "Concluídas"
        // card and its per-task bars) plus the blocked/plan rows.
        var doneSource: [TaskItem]
        var blockedRows: [BlockedLine]
        var planRows: [PlanLine]
        var focus: Int

        if isToday {
            // Only tasks completed today belong in today's summary.
            doneSource = doneTasks(on: now)
            blockedRows = blockedTasks.map { BlockedLine(title: $0.title, reason: $0.reason ?? "", details: $0.details) }
            planRows = nextTasks.map { PlanLine(title: $0.title, estimateLabel: TimeFormat.minutes($0.estimate), details: $0.details) }
                + blockedTasks.map { PlanLine(title: $0.title + " (desbloquear)", estimateLabel: TimeFormat.minutes($0.estimate), details: $0.details) }
            // Focus = live work (active/blocked/queued) + time on tasks finished
            // today. Completions carried over from other days are excluded so the
            // total reflects only today.
            let liveSeconds = tasks.filter { $0.state != .done }.reduce(0) { $0 + $1.seconds }
            focus = liveSeconds + doneSource.reduce(0) { $0 + $1.seconds }
        } else {
            let target = dayDate(offset: offset, now: now)
            displayDate = target
            dateLabel = PtBrDates.long(target)
            planCardLabel = "Planejadas"
            planTitle = "PLANEJADO PARA O DIA SEGUINTE"
            subtitle = "Histórico · " + (offset == 1 ? "ontem" : "\(offset) dias atrás")

            // Real history: tasks completed on that calendar day. Blocked/plan are
            // ephemeral states with no per-day snapshot.
            doneSource = doneTasks(on: target)
            blockedRows = []
            planRows = []
            focus = doneSource.reduce(0) { $0 + $1.seconds }
            if doneSource.isEmpty { isEmpty = true }
        }

        // Done rows, sorted by time spent, each carrying a relative bar width.
        let maxDoneSeconds = max(1, doneSource.map { $0.seconds }.max() ?? 1)
        let doneRows = doneSource
            .sorted { $0.seconds > $1.seconds }
            .map { task in
                DoneLine(
                    title: task.title,
                    secondsLabel: TimeFormat.duration(task.seconds),
                    project: task.project,
                    width: max(2, Int((Double(task.seconds) / Double(maxDoneSeconds) * 100).rounded())),
                    details: task.details
                )
            }

        let text = buildText(
            dateLabel: dateLabel, isEmpty: isEmpty, isToday: isToday,
            focusSeconds: focus, done: doneRows, blocked: blockedRows, plan: planRows,
            current: current
        )

        return Report(
            date: displayDate, dateLabel: dateLabel, subtitle: subtitle,
            isEmpty: isEmpty, isToday: isToday,
            doneCount: doneRows.count, blockedCount: blockedRows.count, planCount: planRows.count,
            focusLabel: TimeFormat.duration(focus),
            doneTasks: doneRows, blockedTasks: blockedRows, planList: planRows,
            planCardLabel: planCardLabel, planTitle: planTitle,
            currentTitle: isToday ? current?.title : nil,
            currentSecondsLabel: isToday ? current.map { TimeFormat.duration($0.seconds) } : nil,
            currentEstimateLabel: isToday ? current.map { TimeFormat.minutes($0.estimate) } : nil,
            currentDetails: isToday ? current?.details : nil,
            text: text
        )
    }

    // MARK: - Helpers

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
