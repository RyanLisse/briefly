import Foundation

public struct GmailProvider: Provider {
    public let id = "gmail"
    public let dependencyId = "gog"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: "gog")
        guard isPresent else { return .missingDependency }
        
        // Smoke test: check if authenticated
        do {
            let output = try await executor.execute("gog", arguments: ["gmail", "list", "--limit", "1"])
            if !output.contains("Error: Unauthenticated") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'gog login' in your terminal.")
            }
        } catch {
            return .unauthenticated(instructions: "Please run 'gog login' in your terminal.")
        }
    }

    public func fetchEmails(for date: Date, limit: Int) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        // Search for unread emails since the date
        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        let query = "is:unread after:\(dateString)"
        let output = try await executor.execute("gog", arguments: ["gmail", "search", query, "--limit", "\(limit)", "--json"])
        
        // Placeholder parsing
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}
