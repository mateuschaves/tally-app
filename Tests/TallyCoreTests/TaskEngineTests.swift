import XCTest
@testable import TallyCore

final class TaskEngineTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func uuid(_ n: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-0000000000" + String(format: "%02d", n))!
    }

    private func task(_ id: Int, _ state: TaskState, seconds: Int = 0) -> TaskItem {
        TaskItem(id: uuid(id), title: "T\(id)", seconds: seconds, state: state)
    }

    private func state(_ tasks: [TaskItem], _ id: Int) -> TaskState? {
        tasks.first { $0.id == uuid(id) }?.state
    }

    // MARK: - Seed

    func testSeed() {
        let seeded = TaskEngine.seed(now: now)
        XCTAssertEqual(seeded.count, 7)
        XCTAssertEqual(seeded.filter { $0.state == .now }.count, 1)
        XCTAssertEqual(seeded.filter { $0.state == .done }.count, 2)
        XCTAssertEqual(seeded.filter { $0.state == .blocked }.count, 1)
    }

    // MARK: - Normalize

    func testNormalizePromotesFirstNext() {
        let tasks = [task(1, .next), task(2, .next)]
        let normalized = TaskEngine.normalize(tasks, now: now)
        XCTAssertEqual(state(normalized, 1), .now)
        XCTAssertEqual(state(normalized, 2), .next)
    }

    func testNormalizeNoopWhenActiveExists() {
        let tasks = [task(1, .now), task(2, .next)]
        let normalized = TaskEngine.normalize(tasks, now: now)
        XCTAssertEqual(state(normalized, 1), .now)
        XCTAssertEqual(state(normalized, 2), .next)
    }

    // MARK: - Mutations

    func testCompletePromotesNext() {
        let tasks = [task(1, .now), task(2, .next)]
        let result = TaskEngine.complete(tasks, id: uuid(1), now: now)
        XCTAssertEqual(state(result, 1), .done)
        XCTAssertEqual(state(result, 2), .now)
        XCTAssertEqual(result.first { $0.id == uuid(1) }?.doneAt, now)
    }

    func testStartSwapsActive() {
        let tasks = [task(1, .now), task(2, .next), task(3, .next)]
        let result = TaskEngine.start(tasks, id: uuid(3), now: now)
        XCTAssertEqual(state(result, 3), .now)
        XCTAssertEqual(state(result, 1), .next)
        XCTAssertEqual(state(result, 2), .next)
    }

    func testStartUnknownIdKeepsActive() {
        let tasks = [task(1, .now), task(2, .next)]
        let result = TaskEngine.start(tasks, id: uuid(99), now: now)
        XCTAssertEqual(state(result, 1), .now) // not demoted without a replacement
        XCTAssertEqual(state(result, 2), .next)
    }

    func testStartClearsStaleFields() {
        var blocked = task(1, .blocked); blocked.reason = "x"
        var done = task(2, .done); done.doneAt = now
        let tasks = [blocked, done, task(3, .now)]
        let result = TaskEngine.start(tasks, id: uuid(1), now: now)
        let started = result.first { $0.id == uuid(1) }
        XCTAssertEqual(started?.state, .now)
        XCTAssertNil(started?.reason)
        XCTAssertNil(started?.doneAt)
    }

    func testBlockSetsReasonAndPromotesNext() {
        let tasks = [task(1, .now), task(2, .next)]
        let result = TaskEngine.block(tasks, id: uuid(1), reason: "Aguardando revisão", now: now)
        XCTAssertEqual(state(result, 1), .blocked)
        XCTAssertEqual(result.first { $0.id == uuid(1) }?.reason, "Aguardando revisão")
        XCTAssertEqual(state(result, 2), .now)
    }

    func testBlockEmptyReasonFallsBack() {
        let tasks = [task(1, .now)]
        let result = TaskEngine.block(tasks, id: uuid(1), reason: "   ", now: now)
        XCTAssertEqual(result.first { $0.id == uuid(1) }?.reason, "Sem motivo informado")
    }

    func testUnblockReturnsToQueue() {
        let tasks = [task(1, .blocked), task(2, .now)]
        let result = TaskEngine.unblock(tasks, id: uuid(1), now: now)
        XCTAssertEqual(state(result, 1), .next)
        XCTAssertEqual(state(result, 2), .now)
        XCTAssertNil(result.first { $0.id == uuid(1) }?.reason)
    }

    func testAddWhenActiveQueues() {
        let tasks = [task(1, .now)]
        let result = TaskEngine.add(tasks, title: "Nova", now: now)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.last?.state, .next)
        XCTAssertEqual(result.last?.title, "Nova")
    }

    func testAddWhenIdleBecomesActive() {
        let result = TaskEngine.add([], title: "Primeira", now: now)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.state, .now)
    }

    func testAddEmptyTitleIsNoop() {
        let tasks = [task(1, .now)]
        let result = TaskEngine.add(tasks, title: "   ", now: now)
        XCTAssertEqual(result.count, 1)
    }

    func testTickIncrementsActiveOnly() {
        let tasks = [task(1, .now, seconds: 5), task(2, .next, seconds: 0)]
        let ticked = TaskEngine.tick(tasks, paused: false, now: now)
        XCTAssertEqual(ticked.first { $0.id == uuid(1) }?.seconds, 6)
        XCTAssertEqual(ticked.first { $0.id == uuid(2) }?.seconds, 0)
    }

    func testTickPausedIsNoop() {
        let tasks = [task(1, .now, seconds: 5)]
        let ticked = TaskEngine.tick(tasks, paused: true, now: now)
        XCTAssertEqual(ticked.first { $0.id == uuid(1) }?.seconds, 5)
    }

    // MARK: - Delete

    func testDeleteRemovesTask() {
        let tasks = [task(1, .now), task(2, .next)]
        let result = TaskEngine.delete(tasks, id: uuid(2), now: now)
        XCTAssertEqual(result.count, 1)
        XCTAssertNil(result.first { $0.id == uuid(2) })
    }

    func testDeleteActivePromotesNext() {
        let tasks = [task(1, .now), task(2, .next), task(3, .next)]
        let result = TaskEngine.delete(tasks, id: uuid(1), now: now)
        XCTAssertEqual(state(result, 2), .now)
        XCTAssertEqual(state(result, 3), .next)
    }

    func testDeleteUnknownIdIsNoop() {
        let tasks = [task(1, .now)]
        let result = TaskEngine.delete(tasks, id: uuid(9), now: now)
        XCTAssertEqual(result, tasks)
    }
}
