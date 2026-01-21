import Foundation
import ElevenLabsKit

public struct ElevenLabsVoiceEngine: VoiceEngine {
    public let kind: VoiceEngineKind = .cloud
    private let config: VoiceConfig

    public init(config: VoiceConfig) {
        self.config = config
    }

    public func isHealthy() async -> Bool {
        let apiKey = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ""
        return !apiKey.isEmpty
    }

    public func synthesize(text: String, profile: VoiceProfile, outputURL: URL) async throws -> VoiceGeneration {
        let start = Date()

        let env = ProcessInfo.processInfo.environment
        let apiKey = env["ELEVENLABS_API_KEY"] ?? ""
        let voiceId = env["ELEVENLABS_VOICE_ID"] ?? "21m00Tcm4TlvDq8ikWAM"

        guard !apiKey.isEmpty else {
            throw VoiceEngineError.missingAPIKey("ELEVENLABS_API_KEY")
        }

        let client = ElevenLabsTTSClient(apiKey: apiKey)
        let request = ElevenLabsTTSRequest(text: text, modelId: "eleven_monolingual_v1")
        let audioData = try await client.synthesize(voiceId: voiceId, request: request)
        try audioData.write(to: outputURL, options: .atomic)

        return VoiceGeneration(
            outputURL: outputURL,
            engine: kind,
            profile: profile,
            duration: Date().timeIntervalSince(start)
        )
    }
}
