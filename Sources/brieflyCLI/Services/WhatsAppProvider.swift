import Foundation

public struct WhatsAppProvider: Provider {
    public let id = "whatsapp"
    public let dependencyId = "wacli"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: "wacli")
        guard isPresent else { return .missingDependency }
        
        // Smoke test: check if authenticated
        do {
            let output = try await executor.execute("wacli", arguments: ["status"])
            if output.contains("Logged in") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'wacli login' in your terminal.")
            }
        } catch {
            return .unauthenticated(instructions: "Please run 'wacli login' in your terminal.")
        }
    }

    public func fetchMessages(for date: Date, limit: Int) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        let output = try await executor.execute("wacli", arguments: ["messages", "--date", dateString, "--limit", "\(limit)", "--json"])
        
        // Parsing logic would go here. For now, return raw lines as a placeholder
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}

public enum ProviderError: Error {
    case notReady(ProviderStatus)
}
