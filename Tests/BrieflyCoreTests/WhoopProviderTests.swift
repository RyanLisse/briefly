import XCTest
@testable import Core

final class WhoopProviderTests: XCTestCase {
    func testWhoopProviderId() {
        let provider = WhoopProvider()
        XCTAssertEqual(provider.id, "whoop")
        XCTAssertEqual(provider.dependencyId, "whoopskill")
    }
}
