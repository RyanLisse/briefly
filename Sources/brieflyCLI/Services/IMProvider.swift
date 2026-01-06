import Foundation

public struct IMProvider: Provider {
    public let id = "imessage"
    public let dependencyId = "imsg"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: dependencyId)
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute(dependencyId, arguments: ["chats", "--limit", "1", "--json"])
            if !output.contains("Error") && !output.contains("permission denied") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please ensure Terminal/briefly has Full Disk Access in System Settings.")
            }
        } catch {
            return .unauthenticated(instructions: "Please ensure Terminal/briefly has Full Disk Access in System Settings.")
        }
    }

    public func fetchMessages(for date: Date, limit: Int) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let chatsOutput = try await executor.execute(dependencyId, arguments: ["chats", "--limit", "20", "--json"], timeout: 10.0)
        let iso8601Start = ISO8601DateFormatter().string(from: date)
        
        guard let data = chatsOutput.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return try await withThrowingTaskGroup(of: String?.self) { group in
            for chat in json.prefix(10) {
                guard let chatId = chat["rowid"] as? Int else { continue }
                
                group.addTask {
                    let historyOutput = try await self.executor.execute(
                        self.dependencyId,
                        arguments: ["history", "--chat-id", "\(chatId)", "--start", iso8601Start, "--limit", "\(limit)", "--json"],
                        timeout: 5.0
                    )
                    return historyOutput.isEmpty ? nil : historyOutput
                }
            }
            
            var allMessages: [String] = []
            for try await result in group {
                if let message = result {
                    allMessages.append(message)
                }
            }
            return allMessages
        }
    }
}
