import Foundation
import GabGab

public struct MLXVoiceEngine: VoiceEngine {
    public let kind: VoiceEngineKind = .local
    private let config: VoiceConfig
    private let sessionManager: GabGabSessionManager

    public init(config: VoiceConfig) {
        self.config = config
        self.sessionManager = GabGabSessionManager(serverURL: config.mlxBaseURL)
    }

    public func isHealthy() async -> Bool {
        return await sessionManager.checkHealth()
    }

    public func synthesize(text: String, profile: VoiceProfile, outputURL: URL) async throws -> VoiceGeneration {
        let start = Date()
        
        let audioData = try await sessionManager.synthesizeAudioData(
            text: text,
            voice: config.kokoroVoice,
            urgency: profile == .premium ? "premium" : "normal"
        )
        
        try audioData.write(to: outputURL, options: .atomic)
        
        return VoiceGeneration(
            outputURL: outputURL,
            engine: kind,
            profile: profile,
            duration: Date().timeIntervalSince(start)
        )
    }
}
