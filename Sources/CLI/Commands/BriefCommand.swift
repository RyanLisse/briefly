import ArgumentParser
import Foundation
import Core

public struct BriefCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
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

    @Flag(name: .long, help: "Include yesterday's data for comparison")
    var yesterday: Bool = false

    @Option(name: .shortAndLong, help: "Maximum items to collect from each source")
    var limit: Int = 50

    public init() {}

    public func run() async throws {
        let briefingDate = date.map { DateFormatter.yyyyMMdd.date(from: $0) ?? Date() } ?? Date()
        let service = BriefService()

        if yesterday {
            print("🤖 Generating daily briefs for \(DateFormatter.yyyyMMdd.string(from: briefingDate)) and yesterday...")
        } else {
            print("🤖 Generating daily brief for \(DateFormatter.yyyyMMdd.string(from: briefingDate))...")
        }

        do {
            let (todayBrief, yesterdayBrief) = try await service.generateBriefWithHistory(
                for: briefingDate,
                includeYesterday: yesterday,
                limit: limit,
                includeVoice: voice
            )

            if json {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                encoder.dateEncodingStrategy = .iso8601
                
                if let yesterdayBrief = yesterdayBrief {
                    struct CombinedBriefs: Codable {
                        let today: DailyBrief
                        let yesterday: DailyBrief
                    }
                    let combined = CombinedBriefs(today: todayBrief, yesterday: yesterdayBrief)
                    let jsonData = try encoder.encode(combined)
                    print(String(data: jsonData, encoding: .utf8)!)
                } else {
                    let jsonData = try encoder.encode(todayBrief)
                    print(String(data: jsonData, encoding: .utf8)!)
                }
            } else {
                // Show yesterday's brief first if available
                if let yesterdayBrief = yesterdayBrief {
                    let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: briefingDate) ?? briefingDate
                    print("📝 Daily Brief - \(DateFormatter.yyyyMMdd.string(from: yesterdayDate)) (Yesterday)")
                    print("")
                    printBrief(yesterdayBrief, showVoice: false)
                    print("")
                    print(String(repeating: "=", count: 60))
                    print("")
                }
                
                // Show today's brief
                print("📝 Daily Brief - \(DateFormatter.yyyyMMdd.string(from: briefingDate))")
                print("")
                printBrief(todayBrief, showVoice: voice)
                
                print("---")
                print("*Generated on \(DateFormatter.full.string(from: Date()))*")
            }
        } catch {
            print("❌ Failed to generate brief: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func printBrief(_ brief: DailyBrief, showVoice: Bool) {
        if let summary = brief.summary {
            print("## Summary")
            print(summary)
            print("")
        }

        if let conversationStats = brief.conversationStats, !conversationStats.isEmpty {
            print("## Conversation Activity")
            for stat in conversationStats {
                let sourcesStr = stat.sources.joined(separator: ", ")
                print("- \(stat.contact): \(stat.sent) sent, \(stat.received) received (\(stat.total) total) [\(sourcesStr)]")
            }
            print("")
        }

        if let meetings = brief.meetings, !meetings.isEmpty {
            print("## Meetings & Context")
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

        if let github = brief.github, !github.isEmpty {
            print("## Development")
            github.forEach { print("- \($0)") }
            print("")
        }

        if showVoice, let audioPath = brief.audioPath {
            print("🔊 Voice brief generated: \(audioPath)")
        }
    }
}
