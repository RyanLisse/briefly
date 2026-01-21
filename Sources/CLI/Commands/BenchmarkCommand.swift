import Foundation
import ArgumentParser

/// Benchmark voice engines performance and quality
struct BenchmarkCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "benchmark",
        abstract: "Benchmark voice synthesis engines"
    )

    @Option(name: .long, help: "Text to synthesize for benchmarking")
    var text: String = "This is a test of the voice synthesis system. It should demonstrate the quality and speed of the selected engine."

    @Option(name: .long, help: "Number of benchmark runs")
    var runs: Int = 3

    @Flag(name: .long, help: "Include JSON output")
    var json = false

    func run() async throws {
        print("🎯 Running voice engine benchmark...")
        print("Text length: \(text.count) characters")
        print("Runs: \(runs)")
        print()

        let voiceConfig = VoiceConfig.fromEnvironment()
        let briefService = BriefService()

        var results: [BenchmarkResult] = []

        for run in 1...runs {
            print("Run \(run)/\(runs):")

            let startTime = Date()
            let outputPath = try await briefService.generateVoiceBrief(
                summary: text,
                date: Date(),
                voiceConfig: voiceConfig
            )
            let duration = Date().timeIntervalSince(startTime)

            let fileSize = try? FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? Int64 ?? 0

            let result = BenchmarkResult(
                run: run,
                engine: voiceConfig.engine.rawValue,
                profile: voiceConfig.profile.rawValue,
                runs: runs,
                averageDuration: avgDuration,
                averageFileSize: avgFileSize,
                textLength: text.count,
                results: results
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(summary)
            print("\n📄 JSON Output:")
            print(String(data: jsonData, encoding: .utf8)!)
        }

        // Save to logs directory
        let logsDir = "logs"
        try? FileManager.default.createDirectory(atPath: logsDir, withIntermediateDirectories: true)

        let summary = BenchmarkSummary(
            engine: voiceConfig.engine.rawValue,
            profile: voiceConfig.profile.rawValue,
            runs: runs,
            averageDuration: avgDuration,
            averageFileSize: avgFileSize,
            textLength: text.count,
            results: results
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(summary)

        let timestamp = Int(Date().timeIntervalSince1970)
        let jsonPath = "\(logsDir)/voice-benchmark-\(timestamp).json"
        try jsonData.write(to: URL(fileURLWithPath: jsonPath))

        print("\n💾 Results saved to: \(jsonPath)")
    }
}

struct BenchmarkResult: Codable {
    let run: Int
    let engine: String
    let profile: String
    let duration: TimeInterval
    let fileSize: Int64
    let textLength: Int
    let outputPath: String

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

struct BenchmarkSummary: Codable {
    let engine: String
    let profile: String
    let runs: Int
    let averageDuration: TimeInterval
    let averageFileSize: Double
    let textLength: Int
    let results: [BenchmarkResult]
}