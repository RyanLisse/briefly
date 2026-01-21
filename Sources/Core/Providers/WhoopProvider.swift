import Foundation

public struct WhoopProvider: Provider {
    public let id = "whoop"
    public let dependencyId = "whoopskill"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: dependencyId)
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute(dependencyId, arguments: ["auth", "status"])
            if output.contains("\"authenticated\": true") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'whoopskill auth login' in your terminal.")
            }
        } catch {
            return .unauthenticated(instructions: "Please run 'whoopskill auth login' in your terminal.")
        }
    }

    public func fetchRecovery(for date: Date) async throws -> String {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        let output = try await executor.execute(dependencyId, arguments: ["--date", dateString, "--recovery", "--sleep"])
        
        return output
    }
}
