import XCTest
@testable import TallyCore

final class ReportBuilderTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    func testTodayReportFromSeed() {
        let tasks = TaskEngine.seed(now: now)
        let report = ReportBuilder.build(tasks: tasks, offset: 0, now: now)

        XCTAssertTrue(report.isToday)
        XCTAssertFalse(report.isEmpty)
        // done = tasks 6 & 7; blocked = task 5.
        XCTAssertEqual(report.doneCount, 2)
        XCTAssertEqual(report.blockedCount, 1)
        // plan = 3 next tasks + 1 blocked "(desbloquear)".
        XCTAssertEqual(report.planCount, 4)
        // focus = 1385 + 760 + 900 + 2290 = 5335s → "1h 29m".
        XCTAssertEqual(report.focusLabel, "1h 29m")
        XCTAssertEqual(report.currentTitle, "Revisar PR do módulo de pagamentos")

        XCTAssertTrue(report.text.contains("Foco total: 1h 29m · 2 concluída(s) · 1 impedida(s)"))
        XCTAssertTrue(report.text.contains("▶ Em andamento"))
        XCTAssertTrue(report.text.hasPrefix("Resumo do dia — "))
    }

    func testEmptyPastDayHasNoActivity() {
        // No completions anywhere → any past day is empty (no synthetic history).
        let cal = PtBrDates.calendar
        let wednesday = cal.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 10))!
        let report = ReportBuilder.build(tasks: [], offset: 3, now: wednesday)

        XCTAssertFalse(report.isToday)
        XCTAssertTrue(report.isEmpty)
        XCTAssertEqual(report.doneCount, 0)
        XCTAssertTrue(report.text.hasSuffix("Sem atividade registrada."))
    }

    func testTodayExcludesCompletionsFromOtherDays() {
        // A task finished yesterday lingers in the store (state == .done), but it
        // must not appear in *today's* summary — only tasks completed today do.
        let cal = PtBrDates.calendar
        let today = cal.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 10))!
        let yesterday = cal.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 16))!
        let earlierToday = cal.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 9))!

        var doneYesterday = TaskItem(title: "Concluída ontem", seconds: 1200, state: .done)
        doneYesterday.doneAt = yesterday
        var doneToday = TaskItem(title: "Concluída hoje", seconds: 600, state: .done)
        doneToday.doneAt = earlierToday
        let active = TaskItem(title: "Em andamento", seconds: 300, state: .now)

        let report = ReportBuilder.build(
            tasks: [doneYesterday, doneToday, active], offset: 0, now: today)

        XCTAssertTrue(report.isToday)
        // Only "Concluída hoje" counts — yesterday's completion is filtered out.
        XCTAssertEqual(report.doneCount, 1)
        XCTAssertEqual(report.doneTasks.map(\.title), ["Concluída hoje"])
        XCTAssertFalse(report.text.contains("Concluída ontem"))
        // Focus = active (300) + done today (600); yesterday's 1200s is excluded.
        XCTAssertEqual(report.focusLabel, TimeFormat.duration(900))
    }

    func testPastDayFromRealCompletions() {
        // A task completed "yesterday" shows up in the offset-1 report.
        let cal = PtBrDates.calendar
        let wednesday = cal.date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 10))!
        let yesterday = cal.date(from: DateComponents(year: 2026, month: 7, day: 14, hour: 15))!
        var done = TaskItem(title: "Tarefa de ontem", details: "Revisão final",
                            project: "Backend", seconds: 1800, state: .done)
        done.doneAt = yesterday

        let report = ReportBuilder.build(tasks: [done], offset: 1, now: wednesday)

        XCTAssertFalse(report.isEmpty)
        XCTAssertEqual(report.doneCount, 1)
        let row = report.doneTasks.first
        XCTAssertEqual(row?.title, "Tarefa de ontem")
        XCTAssertEqual(row?.width, 100) // only task → full bar
        XCTAssertEqual(row?.project, "Backend")
        XCTAssertEqual(row?.details, "Revisão final")
        XCTAssertEqual(report.planTitle, "PLANEJADO PARA O DIA SEGUINTE")
        // Today's live tasks must not leak into a past day.
        XCTAssertEqual(report.blockedCount, 0)
    }
}
