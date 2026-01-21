import XCTest
@testable import Core

final class NotesProviderTests: XCTestCase {
    func testNotesProviderId() {
        let provider = NotesProvider()
        XCTAssertEqual(provider.id, "notes")
        XCTAssertEqual(provider.dependencyId, "braindump")
    }
}
