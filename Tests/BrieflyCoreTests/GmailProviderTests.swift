import XCTest
@testable import BrieflyCore

final class GmailProviderTests: XCTestCase {
    func testGmailProviderId() {
        let provider = GmailProvider()
        XCTAssertEqual(provider.id, "gmail")
        XCTAssertEqual(provider.dependencyId, "gog")
    }
}
