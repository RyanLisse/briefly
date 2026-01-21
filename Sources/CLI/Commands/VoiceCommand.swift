import ArgumentParser
import Foundation
import Core

struct VoiceCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "voice",
        abstract: "Voice engine commands",
        subcommands: [Benchmark.self]
    )

    struct Benchmark: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "benchmark",
            abstract: "Benchmark the configured voice engine"
        )

        @Option(name: .long, help: "Voice engine to use (local|cloud). Defaults to VOICE_ENGINE or local.")
        var engine: String?

        @Option(name: .long, help: "Voice profile (normal|premium). Defaults to VOICE_PROFILE or normal.")
        var voiceProfile: String?

        @Option(name: .long, help: "Speech-to-text profile (parakeet|whisper). Defaults to STT_PROFILE or parakeet.")
        var sttProfile: String?

        @Option(name: .long, help: "Voice mode (auto|always|never). Defaults to VOICE_MODE or auto.")
        var voiceMode: String?

        @Option(name: .long, help: "Custom prompt for the benchmark")
        var prompt: String?

        func run() async throws {
            let baseConfig = VoiceConfig.fromEnvironment()
            let config = baseConfig.withOverrides(
                engine: engine.flatMap { VoiceEngineKind(rawValue: $0.lowercased()) },
                profile: voiceProfile.flatMap { VoiceProfile(rawValue: $0.lowercased()) },
                sttProfile: sttProfile.flatMap { STTProfile(rawValue: $0.lowercased()) },
                voiceMode: voiceMode.flatMap { VoiceMode(rawValue: $0.lowercased()) }
            )
            let resolvedConfig = await VoiceEngineFactory.resolveConfig(config: config)

            let benchmarkPrompt = prompt ?? "Good morning. Here's your daily briefing in a concise, clear, and friendly tone."

            let logsURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
                .appendingPathComponent("logs", isDirectory: true)
            try FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)

            let audioURL = logsURL.appendingPathComponent("voice-benchmark-output.mp3")
            let jsonURL = logsURL.appendingPathComponent("voice-benchmark.json")
            let markdownURL = logsURL.appendingPathComponent("voice-benchmark.md")

            let result = try await VoiceBenchmarkRunner.run(prompt: benchmarkPrompt, config: resolvedConfig, outputURL: audioURL)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(result)
            try jsonData.write(to: jsonURL, options: .atomic)

            let markdown = """
            # Voice Benchmark

            - Engine: \(result.engine.rawValue)
            - Profile: \(result.profile.rawValue)
            - Text length: \(result.textLength)
            - Duration (s): \(String(format: "%.3f", result.durationSeconds))
            - Output size (bytes): \(result.outputSizeBytes)
            - CPU user (s): \(String(format: "%.3f", result.cpuUserSeconds))
            - CPU system (s): \(String(format: "%.3f", result.cpuSystemSeconds))
            - Max RSS: \(result.maxResidentSetSize)
            - Created at: \(result.createdAt)

            Audio output: \(audioURL.path)
            """

            try markdown.data(using: .utf8)?.write(to: markdownURL, options: .atomic)

            print("✅ Benchmark complete")
            print("JSON: \(jsonURL.path)")
            print("Markdown: \(markdownURL.path)")
            print("Audio: \(audioURL.path)")
        }
    }
}
