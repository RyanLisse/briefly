import Foundation

public struct GmailProvider: Provider {
    public let id = "gmail"
    public let dependencyId = "gog"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: "gog")
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute("gog", arguments: ["gmail", "labels", "list", "--json"])
            if !output.contains("unauthenticated") && !output.contains("Error") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'gog auth add <your-email>' in your terminal.")
            }
        } catch {
            return .unauthenticated(instructions: "Please run 'gog auth add <your-email>' in your terminal.")
        }
    }

    public func fetchEmails(for date: Date, limit: Int) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let gmailDateFormat = String(format: "%04d/%02d/%02d", components.year!, components.month!, components.day!)
        let query = "after:\(gmailDateFormat)"
        let output = try await executor.execute("gog", arguments: ["gmail", "search", query, "--max", "\(limit)", "--json"])
        
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}
