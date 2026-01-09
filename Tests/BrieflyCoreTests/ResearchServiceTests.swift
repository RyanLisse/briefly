import XCTest
@testable import BrieflyCore

final class ResearchServiceTests: XCTestCase {
    func testResearchServiceInitialization() {
        let service = ResearchService()
        XCTAssertNotNil(service)
    }
}
