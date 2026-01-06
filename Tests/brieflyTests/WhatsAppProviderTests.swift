import XCTest
@testable import brieflyCLI

final class WhatsAppProviderTests: XCTestCase {
    func testWhatsAppProviderId() {
        let provider = WhatsAppProvider()
        XCTAssertEqual(provider.id, "whatsapp")
        XCTAssertEqual(provider.dependencyId, "wacli")
    }
}
