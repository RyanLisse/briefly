// Sources/brieflyCLI/Commands/BriefCommand.swift
import ArgumentParser
import Foundation

struct BriefCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "brief",
        abstract: "Generate a daily briefing",
        discussion: """
        Generate a comprehensive daily briefing by collecting data from:
        - iMessage conversations
        - WhatsApp messages
        - Gmail emails
        - Google Calendar events
        - Reminders and Notes
        - Whoop health metrics

        Outputs both text brief and optional voice synthesis.
        """
    )

    @Option(name: .shortAndLong, help: "Date for the brief (YYYY-MM-DD format, defaults to today)")
    var date: String?

    @Flag(name: .shortAndLong, help: "Generate voice output using ElevenLabs")
    var voice: Bool = false

    @Flag(name: .long, help: "Output in JSON format")
    var json: Bool = false

    @Option(name: .shortAndLong, help: "Maximum items to collect from each source")
    var limit: Int = 50

    mutating func run() async throws {
        let briefingDate = date.map { DateFormatter.yyyyMMdd.date(from: $0) ?? Date() } ?? Date()
        let service = BriefService()

        print("🤖 Generating daily brief for \(DateFormatter.yyyyMMdd.string(from: briefingDate))...")

        do {
            let brief = try await service.generateBrief(
                for: briefingDate,
                limit: limit,
                includeVoice: voice
            )

            if json {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let jsonData = try encoder.encode(brief)
                print(String(data: jsonData, encoding: .utf8)!)
            } else {
                print("📝 Daily Brief - \(DateFormatter.yyyyMMdd.string(from: briefingDate))")
                print("")

                if let meetings = brief.meetings, !meetings.isEmpty {
                    print("## Meetings")
                    meetings.forEach { print("- \($0)") }
                    print("")
                }

                if let communications = brief.communications, !communications.isEmpty {
                    print("## Communications")
                    communications.forEach { print("- \($0)") }
                    print("")
                }

                if let notes = brief.notes, !notes.isEmpty {
                    print("## Notes & Reminders")
                    notes.forEach { print("- \($0)") }
                    print("")
                }

                if let health = brief.health, !health.isEmpty {
                    print("## Health & Fitness")
                    health.forEach { print("- \($0)") }
                    print("")
                }

                if voice, let audioPath = brief.audioPath {
                    print("🔊 Voice brief generated: \(audioPath)")
                }

                print("---")
                print("*Generated on \(DateFormatter.full.string(from: Date()))*")
            }
        } catch {
            print("❌ Failed to generate brief: \(error.localizedDescription)")
            throw error
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }()
}