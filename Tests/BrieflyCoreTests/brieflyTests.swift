// Tests/brieflyTests/brieflyTests.swift
import XCTest
@testable import BrieflyCore

final class brieflyTests: XCTestCase {
    func testDailyBriefCreation() throws {
        let date = Date()
        let brief = DailyBrief(
            date: date,
            meetings: ["Team standup at 10 AM"],
            communications: ["Important email from client"],
            notes: ["Buy groceries"],
            health: ["Good night's sleep: 8.2 hours"]
        )

        XCTAssertEqual(brief.date, date)
        XCTAssertEqual(brief.meetings?.count, 1)
        XCTAssertEqual(brief.communications?.count, 1)
        XCTAssertEqual(brief.notes?.count, 1)
        XCTAssertEqual(brief.health?.count, 1)
    }

    func testBriefServiceInitialization() throws {
        let service = BriefService()
        XCTAssertNotNil(service)
    }
}