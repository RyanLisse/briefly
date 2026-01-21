import Foundation

public struct BirdProvider: Provider {
    public let id = "bird"
    public let dependencyId = "bird"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: dependencyId)
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute(dependencyId, arguments: ["whoami"])
            if output.contains("@") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'bird check' to ensure you are logged into X/Twitter.")
            }
        } catch {
            return .unauthenticated(instructions: "Please ensure 'bird' is correctly configured.")
        }
    }

    public func fetchActivity(for date: Date, limit: Int) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        // Fetch mentions or timeline - here we'll search for notifications or similar
        // For simplicity, we'll just get the latest 5 items
        let output = try await executor.execute(dependencyId, arguments: ["search", "from:me", "-n", "\(limit)"])
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}
