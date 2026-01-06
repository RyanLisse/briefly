import XCTest
@testable import brieflyCLI

final class ResearchServiceTests: XCTestCase {
    func testResearchServiceInitialization() {
        let service = ResearchService()
        XCTAssertNotNil(service)
    }
}
