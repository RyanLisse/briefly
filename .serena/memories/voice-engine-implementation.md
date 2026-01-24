VoiceEngine abstraction implemented with protocol and concrete engines:

VoiceEngine Protocol (Sources/Core/Voice/VoiceEngine.swift):
- async generateAudio(text: String) -> URL
- var description: String
- var supportedProfiles: [String]

MLXVoiceEngine (Sources/Core/Voice/MLXVoiceEngine.swift):
- Uses GabGab for local MLX models (Kokoro-82M/LFM 2.5)
- Default engine for privacy and cost benefits
- Supports multiple voices/profiles

ElevenLabsVoiceEngine (Sources/Core/Voice/ElevenLabsVoiceEngine.swift):
- Cloud fallback engine
- Requires API key
- Used when local models fail or for enhanced voices

BriefService (Sources/Core/Services/BriefService.swift):
- Dependency injection of VoiceEngine
- Defaults to MLXVoiceEngine
- Falls back to ElevenLabs on failure

CLI integration: --engine flag in BriefCommand allows selection
MCP server: engine parameter in generate_daily_brief tool