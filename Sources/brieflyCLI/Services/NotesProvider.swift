import Foundation

public struct NotesProvider: Provider {
    public let id = "notes"
    public let dependencyId = "braindump"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: dependencyId)
        guard isPresent else { return .missingDependency }
        
        do {
            _ = try await executor.execute(dependencyId, arguments: ["notes", "folders", "--json"])
            return .ready
        } catch {
            return .unauthenticated(instructions: "Braindump failed. Install: cd ~/Developer/Braindump && swift build -c release && cp .build/release/braindump /usr/local/bin/")
        }
    }

    public func fetchNotes(modifiedAfter date: Date) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let output = try await executor.execute(dependencyId, arguments: ["notes", "list", "--json"])
        
        return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
}
