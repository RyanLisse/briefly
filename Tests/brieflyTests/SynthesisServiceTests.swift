import XCTest
@testable import brieflyCLI

final class SynthesisServiceTests: XCTestCase {
    func testSynthesisServiceInitialization() {
        let service = SynthesisService()
        XCTAssertNotNil(service)
    }
}
