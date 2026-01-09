import XCTest
@testable import BrieflyCore

final class WhatsAppProviderTests: XCTestCase {
    func testWhatsAppProviderId() {
        let provider = WhatsAppProvider()
        XCTAssertEqual(provider.id, "whatsapp")
        XCTAssertEqual(provider.dependencyId, "wacli")
    }
}
