import Foundation

public struct WhatsAppProvider: Provider {
    public let id = "whatsapp"
    public let dependencyId = "wacli"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: "wacli")
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute("wacli", arguments: ["doctor"])
            if output.contains("authenticated") || output.contains("OK") || !output.contains("not logged in") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'wacli auth' in your terminal to authenticate via QR code.")
            }
        } catch {
            return .unauthenticated(instructions: "Please run 'wacli auth' in your terminal to authenticate via QR code.")
        }
    }

    public func fetchMessages(for date: Date, limit: Int) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        let output = try await executor.execute(
            "wacli",
            arguments: ["messages", "list", "--after", dateString, "--limit", "\(limit)", "--json"]
        )
        
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
    
    /// Fetch messages as structured Message objects for analytics
    public func fetchStructuredMessages(for date: Date, limit: Int) async throws -> [Message] {
        let jsonStrings = try await fetchMessages(for: date, limit: limit)
        return MessageParser.parseWhatsAppMessages(jsonStrings)
    }
}

