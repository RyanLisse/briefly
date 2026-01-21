import Foundation

public struct CalyProvider: Provider {
    public let id = "caly"
    public let dependencyId = "caly"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: dependencyId)
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute(dependencyId, arguments: ["calendars"])
            if !output.contains("Error") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please ensure Caly has calendar access in System Settings.")
            }
        } catch {
            return .unauthenticated(instructions: "Please ensure Caly is correctly installed.")
        }
    }

    public func fetchEvents(for date: Date, limit: Int = 20) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        // Caly list for a specific day
        let output = try await executor.execute(dependencyId, arguments: ["list", "--from", dateString, "--to", dateString, "--limit", "\(limit)"])
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}
