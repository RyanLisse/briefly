import Foundation

public struct SmartTurnAnalyzer {
    private let enabled: Bool

    public init(enabled: Bool = SmartTurnAnalyzer.isEnabledByDefault()) {
        self.enabled = enabled
    }

    public func waitForTurnCompletion() async {
        guard enabled else {
            FileLogger.appendLine("smart_turn=disabled reason=env_override", to: "smart_turn.log")
            return
        }

        // Placeholder: integrate Parakeet stream or MLX server events.
        // For now, we simply log that Smart Turn is enabled.
        FileLogger.appendLine("smart_turn=enabled status=ready", to: "smart_turn.log")
    }

    public static func isEnabledByDefault() -> Bool {
        let env = ProcessInfo.processInfo.environment
        if let value = env["SMART_TURN"]?.lowercased(), value == "off" {
            return false
        }
        if let value = env["VOICE_MODE"]?.lowercased(), value == "legacy" {
            return false
        }
        return true
    }
}
