import XCTest
@testable import TallyCore

final class TimeFormatTests: XCTestCase {

    func testClock() {
        XCTAssertEqual(TimeFormat.clock(0), "00:00")
        XCTAssertEqual(TimeFormat.clock(65), "01:05")
        XCTAssertEqual(TimeFormat.clock(600), "10:00")
        XCTAssertEqual(TimeFormat.clock(3661), "1:01:01")
        XCTAssertEqual(TimeFormat.clock(-5), "00:00")
    }

    func testDuration() {
        XCTAssertEqual(TimeFormat.duration(30), "30s")
        XCTAssertEqual(TimeFormat.duration(59), "59s")
        XCTAssertEqual(TimeFormat.duration(60), "1m")
        XCTAssertEqual(TimeFormat.duration(1385), "23m")
        XCTAssertEqual(TimeFormat.duration(3600), "1h 00m")
        XCTAssertEqual(TimeFormat.duration(5335), "1h 29m")
    }

    func testMinutes() {
        XCTAssertEqual(TimeFormat.minutes(15), "15m")
        XCTAssertEqual(TimeFormat.minutes(45), "45m")
        XCTAssertEqual(TimeFormat.minutes(60), "1h")
        XCTAssertEqual(TimeFormat.minutes(90), "1h30")
        XCTAssertEqual(TimeFormat.minutes(120), "2h")
        XCTAssertEqual(TimeFormat.minutes(30.4), "30m")
    }
}
