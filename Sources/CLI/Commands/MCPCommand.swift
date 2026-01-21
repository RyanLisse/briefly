// Sources/CLI/Commands/MCPCommand.swift
import ArgumentParser
import BrieflyMCP

struct MCPCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp",
        abstract: "MCP server commands",
        subcommands: [Serve.self, ListMCPTools.self],
        defaultSubcommand: Serve.self
    )

    struct Serve: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "serve",
            abstract: "Start MCP server (stdio transport)"
        )

        mutating func run() async throws {
            let server = BrieflyMCPServer()
            try await server.run()
        }
    }

    struct ListMCPTools: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "tools",
            abstract: "List available MCP tools"
        )

        func run() throws {
            print("Available MCP Tools for briefly:")
            print("")
            print("📅 generate_daily_brief")
            print("   Generate a comprehensive daily briefing from all data sources")
            print("   Parameters:")
            print("   - date: Date for the brief (optional, defaults to today)")
            print("   - limit: Maximum items to collect (optional, defaults to 50)")
            print("   - voice: Generate voice output (optional, defaults to false)")
            print("   - engine: Voice engine (local|cloud, optional)")
            print("   - voice_profile: Voice profile (normal|premium, optional)")
            print("   - stt_profile: STT profile (parakeet|whisper, optional)")
            print("   - voice_mode: Voice mode (auto|always|never, optional)")
            print("")
            print("🎵 generate_voice_brief")
            print("   Generate only voice output for a given text brief")
            print("   Parameters:")
            print("   - text: The brief text to convert to speech")
            print("   - engine: Voice engine (local|cloud, optional)")
            print("   - voice_profile: Voice profile (normal|premium, optional)")
        }
    }
}