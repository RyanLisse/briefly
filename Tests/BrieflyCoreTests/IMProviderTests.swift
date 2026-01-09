import XCTest
@testable import BrieflyCore

final class IMProviderTests: XCTestCase {
    func testIMProviderId() {
        let provider = IMProvider()
        XCTAssertEqual(provider.id, "imessage")
        XCTAssertEqual(provider.dependencyId, "imsg")
    }
}
