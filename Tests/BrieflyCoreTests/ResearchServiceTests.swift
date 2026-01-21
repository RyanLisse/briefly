import XCTest
@testable import Core

final class ResearchServiceTests: XCTestCase {
    func testResearchServiceInitialization() {
        let service = ResearchService()
        XCTAssertNotNil(service)
    }
}
