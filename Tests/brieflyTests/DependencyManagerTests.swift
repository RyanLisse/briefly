import XCTest
@testable import brieflyCLI

final class DependencyManagerTests: XCTestCase {
    func testDependencyRegistry() async {
        let manager = DependencyManager.shared
        let deps = await manager.allDependencies
        XCTAssertFalse(deps.isEmpty)
        XCTAssertTrue(deps.contains(where: { $0.id == "wacli" }))
    }

    func testDependencyVerification() async {
        let manager = DependencyManager.shared
        let isEchoPresent = await manager.verifyPresence(of: "echo")
        XCTAssertTrue(isEchoPresent)
        
        let isFakePresent = await manager.verifyPresence(of: "nonexistent-binary-xyz")
        XCTAssertFalse(isFakePresent)
    }
}
