import Foundation

public protocol Provider: Sendable {
    var id: String { get }
    var dependencyId: String { get }
    func checkStatus() async throws -> ProviderStatus
}

public enum ProviderStatus: Sendable, Equatable {
    case ready
    case missingDependency
    case unauthenticated(instructions: String)
}

public enum ProviderError: Error {
    case notReady(ProviderStatus)
}
