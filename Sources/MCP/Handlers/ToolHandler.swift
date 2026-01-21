import Foundation
import MCP
import Logging
import Core

public actor ToolHandler {
    private let logger: Logger

    public init(logger: Logger = Logger(label: "com.steipete.briefly.mcp.tools")) {
        self.logger = logger
    }

    public func listTools() -> ListTools.Result {
        ListTools.Result(tools: Self.allTools)
    }

    public func callTool(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        switch params.name {
        case "generate_daily_brief":
            return try await handleGenerateBrief(params)
        case "generate_voice_brief":
            return try await handleVoiceBrief(params)
        default:
            throw MCPError.methodNotFound("Unknown tool: \(params.name)")
        }
    }

    private func handleGenerateBrief(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        let dateString = params.arguments?["date"]?.stringValue
        let limit = params.arguments?["limit"]?.intValue ?? 50
        let includeVoice = params.arguments?["voice"]?.boolValue ?? false
        let engineOverride = params.arguments?["engine"]?.stringValue
        let profileOverride = params.arguments?["voice_profile"]?.stringValue
        let sttOverride = params.arguments?["stt_profile"]?.stringValue
        let modeOverride = params.arguments?["voice_mode"]?.stringValue

        let date = dateString.flatMap { DateFormatter.yyyyMMdd.date(from: $0) } ?? Date()

        let briefService = BriefService()
        var config = VoiceConfig.fromEnvironment().withOverrides(
            engine: engineOverride.flatMap { VoiceEngineKind(rawValue: $0.lowercased()) },
            profile: profileOverride.flatMap { VoiceProfile(rawValue: $0.lowercased()) },
            sttProfile: sttOverride.flatMap { STTProfile(rawValue: $0.lowercased()) },
            voiceMode: modeOverride.flatMap { VoiceMode(rawValue: $0.lowercased()) }
        )
        if includeVoice || config.voiceMode == .always {
            config = await VoiceEngineFactory.resolveConfig(config: config)
        }

        do {
            let brief = try await briefService.generateBrief(
                for: date,
                limit: limit,
                includeVoice: includeVoice,
                voiceConfig: config
            )

            var content: [Tool.Content] = []

            var summary = "## Daily Brief - \(DateFormatter.yyyyMMdd.string(from: date))\n\n"

            if let llmSummary = brief.summary {
                summary += "### Executive Summary\n\(llmSummary)\n\n"
            }

            if let meetings = brief.meetings, !meetings.isEmpty {
                summary += "### Meetings & Context\n"
                meetings.forEach { summary += "- \($0)\n" }
                summary += "\n"
            }

            if let communications = brief.communications, !communications.isEmpty {
                summary += "### Communications\n"
                communications.forEach { summary += "- \($0)\n" }
                summary += "\n"
            }

            if let notes = brief.notes, !notes.isEmpty {
                summary += "### Notes & Reminders\n"
                notes.forEach { summary += "- \($0)\n" }
                summary += "\n"
            }

            if let health = brief.health, !health.isEmpty {
                summary += "### Health & Fitness\n"
                health.forEach { summary += "- \($0)\n" }
                summary += "\n"
            }

            if let github = brief.github, !github.isEmpty {
                summary += "### Development\n"
                github.forEach { summary += "- \($0)\n" }
                summary += "\n"
            }

            content.append(.text(summary))

            if let audioPath = brief.audioPath {
                content.append(.text("🎵 Voice brief generated: \(audioPath)"))
            }

            return .init(content: content)

        } catch {
            return CallTool.Result(content: [.text("❌ Failed to generate brief: \(error.localizedDescription)")])
        }
    }

    private func handleVoiceBrief(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        guard let text = params.arguments?["text"]?.stringValue else {
            throw MCPError.invalidParams("Missing required 'text' parameter")
        }

        let briefService = BriefService()
        let engineOverride = params.arguments?["engine"]?.stringValue
        let profileOverride = params.arguments?["voice_profile"]?.stringValue
        var config = VoiceConfig.fromEnvironment().withOverrides(
            engine: engineOverride.flatMap { VoiceEngineKind(rawValue: $0.lowercased()) },
            profile: profileOverride.flatMap { VoiceProfile(rawValue: $0.lowercased()) },
            sttProfile: nil,
            voiceMode: nil
        )
        config = await VoiceEngineFactory.resolveConfig(config: config)
        do {
            let audioPath = try await briefService.generateVoiceBrief(summary: text, date: Date(), voiceConfig: config)
            return .init(content: [.text("✅ Voice brief generated: \(audioPath)")])
        } catch {
            return CallTool.Result(content: [.text("❌ Failed to generate voice brief: \(error.localizedDescription)")])
        }
    }
}

extension ToolHandler {
    static let allTools: [Tool] = [
        Tool(
            name: "generate_daily_brief",
            description: "Generate a comprehensive daily briefing from communication channels, calendar, and health data",
            inputSchema: .object([
                "properties": .object([
                    "date": .string("Date for the brief in YYYY-MM-DD format (optional, defaults to today)"),
                    "limit": .string("Maximum items to collect from each source (optional, defaults to 50)"),
                    "voice": .string("Generate voice output (optional, defaults to false)"),
                    "engine": .string("Voice engine (local|cloud, optional)"),
                    "voice_profile": .string("Voice profile (normal|premium, optional)"),
                    "stt_profile": .string("STT profile (parakeet|whisper, optional)"),
                    "voice_mode": .string("Voice mode (auto|always|never, optional)")
                ])
            ])
        ),
        Tool(
            name: "generate_voice_brief",
            description: "Convert a text brief to voice using the configured engine",
            inputSchema: .object([
                "properties": .object([
                    "text": .string("The brief text to convert to speech"),
                    "engine": .string("Voice engine (local|cloud, optional)"),
                    "voice_profile": .string("Voice profile (normal|premium, optional)")
                ])
            ])
        )
    ]
}

public enum MCPError: Error, LocalizedError {
    case methodNotFound(String)
    case invalidParams(String)
    case internalError(String)

    public var errorDescription: String? {
        switch self {
        case .methodNotFound(let msg): return "Method not found: \(msg)"
        case .invalidParams(let msg): return "Invalid parameters: \(msg)"
        case .internalError(let msg): return "Internal error: \(msg)"
        }
    }
}
