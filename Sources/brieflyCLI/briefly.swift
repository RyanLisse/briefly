// Sources/brieflyCLI/briefly.swift
import ArgumentParser

public struct briefly: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "briefly",
        abstract: "Generate daily briefings from communication channels and health data",
        version: "1.0.0",
        subcommands: [
            BriefCommand.self,
            MCPCommand.self,
        ],
        defaultSubcommand: BriefCommand.self
    )

    public init() {}
}