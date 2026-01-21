import Foundation
import Logging

/// ElevenLabs cloud voice synthesis engine (legacy/fallback)
public final class ElevenLabsVoiceEngine: VoiceEngine {
    private let logger = Logger(label: "briefly.voice.elevenlabs")
    private let apiKey: String
    private let voiceId: String

    public let name = "ElevenLabsVoiceEngine"

    public init(apiKey: String, voiceId: String) {
        self.apiKey = apiKey
        self.voiceId = voiceId
        logger.info("Initialized ElevenLabsVoiceEngine")
    }

    public func synthesize(text: String, outputPath: String) async throws -> URL {
        logger.info("Starting ElevenLabs synthesis", metadata: [
            "text_length": Logger.MetadataValue.string("\(text.count)")
        ])

        let outputURL = URL(fileURLWithPath: outputPath)

        // Simple ElevenLabs API call (would need proper client implementation)
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_monolingual_v1",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VoiceEngineError.synthesisFailed("ElevenLabs API returned error")
        }

        // Write audio data to file
        try data.write(to: outputURL)

        logger.info("ElevenLabs synthesis completed", metadata: [
            "output_path": Logger.MetadataValue.string(outputPath)
        ])
        return outputURL
    }

    public func isAvailable() async -> Bool {
        // Check API key by making a simple request
        let url = URL(string: "https://api.elevenlabs.io/v1/voices")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "xi-api-key")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            return httpResponse?.statusCode == 200
        } catch {
            logger.warning("ElevenLabs availability check failed", metadata: [
                "error": Logger.MetadataValue.string("\(error)")
            ])
            return false
        }
    }
}