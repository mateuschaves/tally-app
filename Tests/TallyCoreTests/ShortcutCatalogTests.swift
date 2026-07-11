import XCTest
@testable import TallyCore

final class ShortcutCatalogTests: XCTestCase {

    func testDefaultsMatchPrototype() {
        let defaults = ShortcutCatalog.defaults
        XCTAssertEqual(defaults.count, 9)
        XCTAssertEqual(defaults.map(\.id),
                       ["new", "confirmAdd", "complete", "block", "pause",
                        "toggleWidget", "report", "prefs", "close"])
        // Groups follow the screen's section order.
        XCTAssertEqual(Set(defaults.map(\.group)), Set(ShortcutCatalog.groups))
        // Spot-check a combo + its registration data (⇧⌘D → kVK_ANSI_D = 2).
        let complete = defaults.first { $0.id == "complete" }!
        XCTAssertEqual(complete.keys, ["⇧", "⌘", "D"])
        XCTAssertEqual(complete.keyCode, 2)
        XCTAssertEqual(complete.carbonModifiers,
                       ShortcutCatalog.Modifier.shift | ShortcutCatalog.Modifier.command)
        XCTAssertTrue(defaults.allSatisfy(\.enabled))
    }

    func testMergeKeepsRecordedComboAndEnabledFlag() {
        var saved = ShortcutCatalog.defaults.first { $0.id == "report" }!
        saved.keys = ["⌥", "⌘", "R"]
        saved.carbonModifiers = ShortcutCatalog.Modifier.option | ShortcutCatalog.Modifier.command
        var disabled = ShortcutCatalog.defaults.first { $0.id == "pause" }!
        disabled.enabled = false

        let merged = ShortcutCatalog.merge(saved: [saved, disabled])

        XCTAssertEqual(merged.count, 9) // every default action still exists
        let report = merged.first { $0.id == "report" }!
        XCTAssertEqual(report.keys, ["⌥", "⌘", "R"])
        XCTAssertFalse(merged.first { $0.id == "pause" }!.enabled)
        // Untouched actions keep their defaults.
        XCTAssertEqual(merged.first { $0.id == "new" }!.keys, ["⌘", "K"])
    }

    func testMergeDropsUnknownIdsAndEmptySnapshotFallsBack() {
        let ghost = ShortcutSpec(id: "ghost", group: "FOCO", icon: "?", name: "Fantasma", keys: ["⌘", "G"])
        XCTAssertFalse(ShortcutCatalog.merge(saved: [ghost]).contains { $0.id == "ghost" })
        XCTAssertEqual(ShortcutCatalog.merge(saved: []), ShortcutCatalog.defaults)
    }

    func testConflictDetection() {
        let all = ShortcutCatalog.defaults
        // ⌘K belongs to "new" → recording it on "report" clashes.
        XCTAssertEqual(ShortcutCatalog.conflict(in: all, combo: "⌘+K", excluding: "report")?.id, "new")
        // Same combo on its own row is not a conflict.
        XCTAssertNil(ShortcutCatalog.conflict(in: all, combo: "⌘+K", excluding: "new"))
        // Disabled shortcuts don't claim their combo.
        var mutable = all
        mutable[0].enabled = false // "new"
        XCTAssertNil(ShortcutCatalog.conflict(in: mutable, combo: "⌘+K", excluding: "report"))
    }

    func testSearchMatchesNameAndHint() {
        let new = ShortcutCatalog.defaults[0]
        XCTAssertTrue(ShortcutCatalog.matches(new, query: "nova"))
        XCTAssertTrue(ShortcutCatalog.matches(new, query: "CAPTURA RÁPIDA".lowercased()))
        XCTAssertFalse(ShortcutCatalog.matches(new, query: "resumo"))
        XCTAssertTrue(ShortcutCatalog.matches(new, query: "   "))
    }
}
