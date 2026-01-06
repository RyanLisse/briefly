// Sources/brieflyCLI/MCP/brieflyMCPServer.swift
import MCP
import Foundation
import Logging

public actor brieflyMCPServer {
    private let logger: Logger
    private let allTools: [Tool]

    public init() {
        self.logger = Logger(label: "com.steipete.briefly.mcp")
        self.allTools = [
            Tool(
                name: "generate_daily_brief",
                description: "Generate a comprehensive daily briefing from communication channels, calendar, and health data",
                inputSchema: .object([
                    "properties": .object([
                        "date": .string("Date for the brief in YYYY-MM-DD format (optional, defaults to today)"),
                        "limit": .string("Maximum items to collect from each source (optional, defaults to 50)"),
                        "voice": .string("Generate voice output using ElevenLabs (optional, defaults to false)")
                    ])
                ])
            ),
            Tool(
                name: "generate_voice_brief",
                description: "Convert a text brief to voice using ElevenLabs",
                inputSchema: .object([
                    "properties": .object([
                        "text": .string("The brief text to convert to speech"),
                        "voice_id": .string("ElevenLabs voice ID (optional, defaults to Roger)")
                    ])
                ])
            )
        ]
    }

    public func run() async throws {
        let server = Server(
            name: "briefly",
            version: "1.0.0",
            capabilities: .init(tools: .init())
        )

        await server.withMethodHandler(ListTools.self) { _ in
            ListTools.Result(tools: self.allTools)
        }

        await server.withMethodHandler(CallTool.self) { params in
            try await self.handleToolCall(params)
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
    }

    private func handleToolCall(_ params: CallTool.Parameters) async throws -> CallTool.Result {
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

        let date = dateString.flatMap { DateFormatter.yyyyMMdd.date(from: $0) } ?? Date()

        let briefService = BriefService()

        do {
            let brief = try await briefService.generateBrief(for: date, limit: limit, includeVoice: includeVoice)

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
        do {
            let audioPath = try await briefService.generateVoiceBrief(summary: text, date: Date())
            return .init(content: [.text("✅ Voice brief generated: \(audioPath)")])
        } catch {
            return CallTool.Result(content: [.text("❌ Failed to generate voice brief: \(error.localizedDescription)")])
        }
    }
}
