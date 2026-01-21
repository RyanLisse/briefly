import Foundation

/// Protocol for voice synthesis engines
public protocol VoiceEngine {
    /// Synthesize text to audio file
    /// - Parameters:
    ///   - text: Text to synthesize
    ///   - outputPath: Path where to save the audio file
    /// - Returns: URL of the generated audio file
    func synthesize(text: String, outputPath: String) async throws -> URL

    /// Get the engine name for logging/metrics
    var name: String { get }

    /// Check if this engine is available/health
    func isAvailable() async -> Bool
}

public enum VoiceEngineError: Error, LocalizedError {
    case missingAPIKey(String)
    case synthesisFailed(String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let key):
            return "Missing required API key: \(key)"
        case .synthesisFailed(let message):
            return "Voice synthesis failed: \(message)"
        }
    }
}

public enum VoiceEngineFactory {
    public static func resolveConfig(config: VoiceConfig) async -> VoiceConfig {
        switch config.engine {
        case .local:
            let localEngine = MLXVoiceEngine(profile: config.profile, baseURL: config.mlxBaseURL)
            if await localEngine.isAvailable() {
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
            let localEngine = MLXVoiceEngine(profile: config.profile, baseURL: config.mlxBaseURL)
            if await localEngine.isAvailable() {
                FileLogger.appendLine("voice_engine=local profile=\(config.profile.rawValue) status=healthy", to: "voice-engine.log")
                return localEngine
            }
            FileLogger.appendLine("voice_engine=local status=unhealthy fallback=cloud", to: "voice-engine.log")
            return ElevenLabsVoiceEngine(
                apiKey: ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? "",
                voiceId: ProcessInfo.processInfo.environment["ELEVENLABS_VOICE_ID"] ?? "21m00Tcm4TlvDq8ikWAM"
            )
        case .cloud:
            FileLogger.appendLine("voice_engine=cloud profile=\(config.profile.rawValue)", to: "voice-engine.log")
            return ElevenLabsVoiceEngine(
                apiKey: ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? "",
                voiceId: ProcessInfo.processInfo.environment["ELEVENLABS_VOICE_ID"] ?? "21m00Tcm4TlvDq8ikWAM"
            )
        }
    }
}