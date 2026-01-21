import XCTest
@testable import Core

final class GmailProviderTests: XCTestCase {
    func testGmailProviderId() {
        let provider = GmailProvider()
        XCTAssertEqual(provider.id, "gmail")
        XCTAssertEqual(provider.dependencyId, "gog")
    }
}
