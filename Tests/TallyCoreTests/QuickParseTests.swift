import XCTest
@testable import TallyCore

final class QuickParseTests: XCTestCase {

    func testFullSyntax() {
        let r = QuickParse.parse("Revisar PR #Backend !alta 45m")
        XCTAssertEqual(r.title, "Revisar PR")
        XCTAssertEqual(r.project, "Backend")
        XCTAssertEqual(r.priority, .alta)
        XCTAssertEqual(r.estimate, 45)
    }

    func testHoursEstimate() {
        let r = QuickParse.parse("Ligar para o cliente 2h")
        XCTAssertEqual(r.title, "Ligar para o cliente")
        XCTAssertNil(r.project)
        XCTAssertEqual(r.estimate, 120)
    }

    func testDecimalHoursAndAccentPriority() {
        let r = QuickParse.parse("Design #UI !média 1,5h")
        XCTAssertEqual(r.title, "Design")
        XCTAssertEqual(r.project, "UI")
        XCTAssertEqual(r.priority, .media) // "média" → "media"
        XCTAssertEqual(r.estimate, 90)
    }

    func testMinutesWordForm() {
        let r = QuickParse.parse("Escrever doc 90 min")
        XCTAssertEqual(r.title, "Escrever doc")
        XCTAssertEqual(r.estimate, 90)
    }

    func testPlainTitle() {
        let r = QuickParse.parse("Só um título simples")
        XCTAssertEqual(r.title, "Só um título simples")
        XCTAssertNil(r.project)
        XCTAssertNil(r.priority)
        XCTAssertNil(r.estimate)
    }

    func testTokensInAnyOrder() {
        let r = QuickParse.parse("!baixa 30m #Design ajustar espaçamento")
        XCTAssertEqual(r.title, "ajustar espaçamento")
        XCTAssertEqual(r.project, "Design")
        XCTAssertEqual(r.priority, .baixa)
        XCTAssertEqual(r.estimate, 30)
    }
}
