import Foundation

public struct VoiceGeneration: Sendable {
    public let outputURL: URL
    public let engine: VoiceEngineKind
    public let profile: VoiceProfile
    public let duration: TimeInterval
}

public protocol VoiceEngine: Sendable {
    var kind: VoiceEngineKind { get }
    func isHealthy() async -> Bool
    func synthesize(text: String, profile: VoiceProfile, outputURL: URL) async throws -> VoiceGeneration
}

public enum VoiceEngineError: Error, LocalizedError {
    case missingAPIKey(String)
    case synthesisFailed(String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let name):
            return "Missing required API key: \(name)"
        case .synthesisFailed(let message):
            return "Voice synthesis failed: \(message)"
        case .invalidResponse:
            return "Invalid response from voice engine"
        }
    }
}

public enum VoiceEngineFactory {
    public static func resolveConfig(config: VoiceConfig) async -> VoiceConfig {
        switch config.engine {
        case .local:
            let localEngine = MLXVoiceEngine(config: config)
            if await localEngine.isHealthy() {
                return config
            }
            FileLogger.appendLine("voice_engine=local status=unhealthy action=fallback", to: "voice-engine.log")
            return config.withOverrides(engine: .cloud, profile: nil, sttProfile: nil, voiceMode: nil)
        case .cloud:
            return config
        }
    }

    public static func resolveEngine(config: VoiceConfig) async -> any VoiceEngine {
        switch config.engine {
        case .local:
            let localEngine = MLXVoiceEngine(config: config)
            if await localEngine.isHealthy() {
                FileLogger.appendLine("voice_engine=local profile=\(config.profile.rawValue) status=healthy", to: "voice-engine.log")
                return localEngine
            }
            FileLogger.appendLine("voice_engine=local status=unhealthy fallback=cloud", to: "voice-engine.log")
            return ElevenLabsVoiceEngine(config: config)
        case .cloud:
            FileLogger.appendLine("voice_engine=cloud profile=\(config.profile.rawValue)", to: "voice-engine.log")
            return ElevenLabsVoiceEngine(config: config)
        }
    }
}
