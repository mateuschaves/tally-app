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

    func testWeekendHistoryIsEmpty() {
        // Monday 2026-07-13; offset 2 lands on Saturday 2026-07-11.
        let cal = PtBrDates.calendar
        let monday = cal.date(from: DateComponents(year: 2026, month: 7, day: 13, hour: 10))!
        let report = ReportBuilder.build(tasks: TaskEngine.seed(now: monday), offset: 2, now: monday)

        XCTAssertFalse(report.isToday)
        XCTAssertTrue(report.isEmpty)
        XCTAssertTrue(report.text.hasSuffix("Sem atividade registrada (fim de semana)."))
    }

    func testHistoryDayHasTemplateData() {
        // Monday 2026-07-13; offset 3 lands on Friday 2026-07-10 (weekday).
        let cal = PtBrDates.calendar
        let monday = cal.date(from: DateComponents(year: 2026, month: 7, day: 13, hour: 10))!
        let report = ReportBuilder.build(tasks: TaskEngine.seed(now: monday), offset: 3, now: monday)

        XCTAssertFalse(report.isEmpty)
        XCTAssertGreaterThan(report.doneCount, 0)
        XCTAssertGreaterThan(report.bars.count, 0)
        XCTAssertEqual(report.planTitle, "◻ PLANEJADO PARA O DIA SEGUINTE")
    }
}
