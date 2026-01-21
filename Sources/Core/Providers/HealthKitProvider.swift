import Foundation

public struct HealthKitProvider: Provider {
    public let id = "healthkit"
    public let dependencyId = "healthsync"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: "healthsync")
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute("healthsync", arguments: ["status"])
            if output.contains("connected") || output.contains("Ready") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'healthsync discover' and 'healthsync scan' to pair your device.")
            }
        } catch {
            return .unauthenticated(instructions: "Please run 'healthsync discover' and 'healthsync scan' to pair your device.")
        }
    }

    public func fetchData(for date: Date) async throws -> String {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        let start = "\(dateString)T00:00:00Z"
        let end = "\(dateString)T23:59:59Z"
        
        let output = try await executor.execute("healthsync", arguments: [
            "fetch", 
            "--start", start, 
            "--end", end, 
            "--types", "steps,heartRate,sleepAnalysis",
            "--format", "json"
        ])
        
        return output
    }
}
