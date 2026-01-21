import XCTest
@testable import Core

final class WhatsAppProviderTests: XCTestCase {
    func testWhatsAppProviderId() {
        let provider = WhatsAppProvider()
        XCTAssertEqual(provider.id, "whatsapp")
        XCTAssertEqual(provider.dependencyId, "wacli")
    }
}
