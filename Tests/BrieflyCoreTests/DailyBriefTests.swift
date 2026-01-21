// Tests/brieflyTests/DailyBriefTests.swift
import XCTest
@testable import Core

final class DailyBriefTests: XCTestCase {
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
        XCTAssertNil(brief.audioPath)
    }

    func testDailyBriefWithAudio() throws {
        let date = Date()
        let audioPath = "/tmp/test.mp3"
        let brief = DailyBrief(
            date: date,
            meetings: nil,
            communications: nil,
            notes: nil,
            health: nil,
            audioPath: audioPath
        )

        XCTAssertEqual(brief.date, date)
        XCTAssertNil(brief.meetings)
        XCTAssertNil(brief.communications)
        XCTAssertNil(brief.notes)
        XCTAssertNil(brief.health)
        XCTAssertEqual(brief.audioPath, audioPath)
    }
}