import XCTest
@testable import BrieflyCore

final class SynthesisServiceTests: XCTestCase {
    func testSynthesisServiceInitialization() {
        let service = SynthesisService()
        XCTAssertNotNil(service)
    }
}
