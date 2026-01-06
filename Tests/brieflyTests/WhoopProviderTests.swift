import XCTest
@testable import brieflyCLI

final class WhoopProviderTests: XCTestCase {
    func testWhoopProviderId() {
        let provider = WhoopProvider()
        XCTAssertEqual(provider.id, "whoop")
        XCTAssertEqual(provider.dependencyId, "whoopskill")
    }
}
