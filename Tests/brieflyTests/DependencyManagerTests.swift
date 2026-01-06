import XCTest
@testable import brieflyCLI

final class DependencyManagerTests: XCTestCase {
    func testDependencyRegistry() async {
        let manager = DependencyManager.shared
        let deps = await manager.allDependencies
        XCTAssertFalse(deps.isEmpty)
        XCTAssertTrue(deps.contains(where: { $0.id == "wacli" }))
    }
}
