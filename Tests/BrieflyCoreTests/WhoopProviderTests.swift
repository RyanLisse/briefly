import XCTest
@testable import BrieflyCore

final class WhoopProviderTests: XCTestCase {
    func testWhoopProviderId() {
        let provider = WhoopProvider()
        XCTAssertEqual(provider.id, "whoop")
        XCTAssertEqual(provider.dependencyId, "whoopskill")
    }
}
