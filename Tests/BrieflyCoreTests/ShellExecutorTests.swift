import XCTest
@testable import BrieflyCore

final class ShellExecutorTests: XCTestCase {
    func testShellExecution() async throws {
        let executor = ShellExecutor()
        let result = try await executor.execute("echo", arguments: ["Hello"])
        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "Hello")
    }
}
