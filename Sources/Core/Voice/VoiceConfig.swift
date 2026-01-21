import Foundation

public enum VoiceEngineKind: String, Codable, Sendable {
    case local
    case cloud
}

public enum VoiceProfile: String, Codable, Sendable {
    case normal
    case premium
}

public enum STTProfile: String, Codable, Sendable {
    case parakeet
    case whisper
}

public enum VoiceMode: String, Codable, Sendable {
    case auto
    case always
    case never
}

public struct VoiceConfig: Codable, Equatable, Sendable {
    public let engine: VoiceEngineKind
    public let profile: VoiceProfile
    public let sttProfile: STTProfile
    public let voiceMode: VoiceMode
    public let mlxBaseURL: URL
    public let kokoroVoice: String

    public init(
        engine: VoiceEngineKind,
        profile: VoiceProfile,
        sttProfile: STTProfile,
        voiceMode: VoiceMode,
        mlxBaseURL: URL,
        kokoroVoice: String
    ) {
        self.engine = engine
        self.profile = profile
        self.sttProfile = sttProfile
        self.voiceMode = voiceMode
        self.mlxBaseURL = mlxBaseURL
        self.kokoroVoice = kokoroVoice
    }

    public static func fromEnvironment() -> VoiceConfig {
        let env = ProcessInfo.processInfo.environment

        let engine = VoiceEngineKind(rawValue: env["VOICE_ENGINE"]?.lowercased() ?? "") ?? .local
        let profile = VoiceProfile(rawValue: env["VOICE_PROFILE"]?.lowercased() ?? "") ?? .normal
        let sttProfile = STTProfile(rawValue: env["STT_PROFILE"]?.lowercased() ?? "") ?? .parakeet
        let voiceMode = VoiceMode(rawValue: env["VOICE_MODE"]?.lowercased() ?? "") ?? .auto

        let baseURLString = env["MLX_AUDIO_BASE_URL"] ?? "http://localhost:8000"
        let mlxBaseURL = URL(string: baseURLString) ?? URL(string: "http://localhost:8000")!
        let kokoroVoice = env["KOKORO_VOICE"] ?? "af"

        return VoiceConfig(
            engine: engine,
            profile: profile,
            sttProfile: sttProfile,
            voiceMode: voiceMode,
            mlxBaseURL: mlxBaseURL,
            kokoroVoice: kokoroVoice
        )
    }

    public func withOverrides(
        engine: VoiceEngineKind?,
        profile: VoiceProfile?,
        sttProfile: STTProfile?,
        voiceMode: VoiceMode?
    ) -> VoiceConfig {
        VoiceConfig(
            engine: engine ?? self.engine,
            profile: profile ?? self.profile,
            sttProfile: sttProfile ?? self.sttProfile,
            voiceMode: voiceMode ?? self.voiceMode,
            mlxBaseURL: mlxBaseURL,
            kokoroVoice: kokoroVoice
        )
    }
}
