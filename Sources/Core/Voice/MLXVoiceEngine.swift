import Foundation
import Logging

/// MLX-based local voice synthesis engine
public final class MLXVoiceEngine: VoiceEngine {
    private let logger = Logger(label: "briefly.voice.mlx")
    private let profile: VoiceProfile
    private let baseURL: URL

    public let name = "MLXVoiceEngine"

    public init(profile: VoiceProfile = .normal, baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.profile = profile
        self.baseURL = baseURL
        logger.info("Initialized MLXVoiceEngine with profile: \(profile.rawValue)")
    }

    public func synthesize(text: String, outputPath: String) async throws -> URL {
        logger.info("Starting MLX synthesis", metadata: [
            "text_length": Logger.MetadataValue.string("\(text.count)"),
            "profile": Logger.MetadataValue.string("\(profile.rawValue)")
        ])

        let outputURL = URL(fileURLWithPath: outputPath)

        // For now, use a simple HTTP request to the MLX server
        // This would be replaced with proper GabGab integration
        let requestURL = baseURL.appendingPathComponent("v1/audio/speech")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "text": text,
            "model": profile == .normal ? "kokoro-82m" : "lfm-2.5-audio",
            "output_path": outputPath
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw VoiceEngineError.synthesisFailed("MLX server returned error")
        }

        logger.info("MLX synthesis completed", metadata: [
            "output_path": Logger.MetadataValue.string(outputPath)
        ])
        return outputURL
    }

    public func isAvailable() async -> Bool {
        // Check if MLX server is running
        let healthURL = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: healthURL)
        request.httpMethod = "GET"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            return httpResponse?.statusCode == 200
        } catch {
            logger.warning("MLX health check failed", metadata: [
                "error": Logger.MetadataValue.string("\(error)")
            ])
            return false
        }
    }
}

enum VoiceEngineError: Error {
    case synthesisFailed(String)
}