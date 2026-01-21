import Foundation
import GabGab

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

/// Voice engine protocol
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