import XCTest
@testable import Core

final class CalendarProviderTests: XCTestCase {
    func testCalendarProviderId() {
        let provider = CalendarProvider()
        XCTAssertEqual(provider.id, "calendar")
        XCTAssertEqual(provider.dependencyId, "gog")
    }
}
