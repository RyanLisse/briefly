import Foundation

public struct CalendarProvider: Provider {
    public let id = "calendar"
    public let dependencyId = "gog"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: dependencyId)
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute(dependencyId, arguments: ["calendar", "calendars", "--json"])
            if !output.contains("unauthenticated") && !output.contains("Error") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'gog auth add <your-email>' in your terminal.")
            }
        } catch {
            return .unauthenticated(instructions: "Please run 'gog auth add <your-email>' in your terminal.")
        }
    }

    public func fetchEvents(for date: Date) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fromString = formatter.string(from: startOfDay)
        let toString = formatter.string(from: endOfDay)
        
        let output = try await executor.execute(
            dependencyId,
            arguments: ["calendar", "events", "--from", fromString, "--to", toString, "--all", "--json"]
        )
        
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}
