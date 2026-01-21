import XCTest
@testable import Core

final class SynthesisServiceTests: XCTestCase {
    func testSynthesisServiceInitialization() {
        let service = SynthesisService()
        XCTAssertNotNil(service)
    }
}
