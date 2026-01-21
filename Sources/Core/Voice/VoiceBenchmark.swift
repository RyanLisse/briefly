import Foundation
import Darwin

public struct VoiceBenchmarkResult: Codable {
    public let engine: VoiceEngineKind
    public let profile: VoiceProfile
    public let textLength: Int
    public let durationSeconds: Double
    public let outputSizeBytes: Int
    public let cpuUserSeconds: Double
    public let cpuSystemSeconds: Double
    public let maxResidentSetSize: Int
    public let createdAt: String
}

public enum VoiceBenchmarkRunner {
    public static func run(prompt: String, config: VoiceConfig, outputURL: URL) async throws -> VoiceBenchmarkResult {
        let usageBefore = ResourceUsage.capture()
        let start = Date()

        let engine = await VoiceEngineFactory.resolveEngine(config: config)
        _ = try await engine.synthesize(text: prompt, outputPath: outputURL.path)

        let usageAfter = ResourceUsage.capture()
        let duration = Date().timeIntervalSince(start)

        let outputSize = (try? Data(contentsOf: outputURL).count) ?? 0

        return VoiceBenchmarkResult(
            engine: config.engine,
            profile: config.profile,
            textLength: prompt.count,
            durationSeconds: duration,
            outputSizeBytes: outputSize,
            cpuUserSeconds: usageAfter.userSeconds - usageBefore.userSeconds,
            cpuSystemSeconds: usageAfter.systemSeconds - usageBefore.systemSeconds,
            maxResidentSetSize: usageAfter.maxResidentSetSize,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}

private struct ResourceUsage {
    let userSeconds: Double
    let systemSeconds: Double
    let maxResidentSetSize: Int

    static func capture() -> ResourceUsage {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let user = Double(usage.ru_utime.tv_sec) + Double(usage.ru_utime.tv_usec) / 1_000_000.0
        let system = Double(usage.ru_stime.tv_sec) + Double(usage.ru_stime.tv_usec) / 1_000_000.0
        return ResourceUsage(
            userSeconds: user,
            systemSeconds: system,
            maxResidentSetSize: Int(usage.ru_maxrss)
        )
    }
}
