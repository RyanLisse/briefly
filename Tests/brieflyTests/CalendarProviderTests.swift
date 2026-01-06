import XCTest
@testable import brieflyCLI

final class CalendarProviderTests: XCTestCase {
    func testCalendarProviderId() {
        let provider = CalendarProvider()
        XCTAssertEqual(provider.id, "calendar")
        XCTAssertEqual(provider.dependencyId, "gog")
    }
}
