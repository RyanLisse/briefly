import Foundation
import ElevenLabsKit

public struct DailyBrief: Codable, Sendable {
    public let date: Date
    public let summary: String?
    public let meetings: [String]?
    public let communications: [String]?
    public let notes: [String]?
    public let health: [String]?
    public let github: [String]?
    public let audioPath: String?
    public let conversationStats: [ConversationStat]?

    public init(date: Date, summary: String? = nil, meetings: [String]? = nil, communications: [String]? = nil,
                notes: [String]? = nil, health: [String]? = nil, github: [String]? = nil, audioPath: String? = nil,
                conversationStats: [ConversationStat]? = nil) {
        self.date = date
        self.summary = summary
        self.meetings = meetings
        self.communications = communications
        self.notes = notes
        self.health = health
        self.github = github
        self.audioPath = audioPath
        self.conversationStats = conversationStats
    }
}

public actor BriefService {
    private let imProvider = IMProvider()
    private let whatsappProvider = WhatsAppProvider()
    private let gmailProvider = GmailProvider()
    private let calendarProvider = CalendarProvider()
    private let notesProvider = NotesProvider()
    private let whoopProvider = WhoopProvider()
    private let githubProvider = GithubProvider()
    private let researchService = ResearchService()
    private let synthesisService = SynthesisService()
    private let analyticsService = ConversationAnalyticsService()

    public init() {}

    /// Generate briefs for today and optionally yesterday
    /// - Parameters:
    ///   - date: Date for the main brief
    ///   - includeYesterday: Whether to also generate yesterday's brief
    ///   - limit: Maximum items to collect from each source
    ///   - includeVoice: Whether to generate voice output
    /// - Returns: Tuple with today's brief and optional yesterday's brief
    public func generateBriefWithHistory(
        for date: Date,
        includeYesterday: Bool = false,
        limit: Int = 50,
        includeVoice: Bool = false
    ) async throws -> (today: DailyBrief, yesterday: DailyBrief?) {
        let todayBrief = try await generateBrief(for: date, limit: limit, includeVoice: includeVoice)
        
        var yesterdayBrief: DailyBrief? = nil
        if includeYesterday {
            let calendar = Calendar.current
            if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) {
                yesterdayBrief = try await generateBrief(for: yesterdayDate, limit: limit, includeVoice: false)
            }
        }
        
        return (today: todayBrief, yesterday: yesterdayBrief)
    }
    
    public func generateBrief(for date: Date, limit: Int = 50, includeVoice: Bool = false) async throws -> DailyBrief {
        print("📊 Gathering data from all sources in parallel...")

        return try await withThrowingTaskGroup(of: DataSourceResult.self) { group in
            group.addTask {
                do {
                    return .imessage(try await self.imProvider.fetchMessages(for: date, limit: limit))
                } catch {
                    print("⚠️ iMessage fetch failed: \(error)")
                    return .imessage([])
                }
            }
            group.addTask {
                do {
                    return .whatsapp(try await self.whatsappProvider.fetchMessages(for: date, limit: limit))
                } catch {
                    print("⚠️ WhatsApp fetch failed: \(error)")
                    return .whatsapp([])
                }
            }
            group.addTask {
                do {
                    return .gmail(try await self.gmailProvider.fetchEmails(for: date, limit: limit))
                } catch {
                    print("⚠️ Gmail fetch failed: \(error)")
                    return .gmail([])
                }
            }
            group.addTask {
                do {
                    return .calendar(try await self.calendarProvider.fetchEvents(for: date))
                } catch {
                    print("⚠️ Calendar fetch failed: \(error)")
                    return .calendar([])
                }
            }
            // group.addTask {
            //     do {
            //         return .notes(try await self.notesProvider.fetchNotes(modifiedAfter: date))
            //     } catch {
            //         print("⚠️ Notes fetch failed: \(error)")
            //         return .notes([])
            //     }
            // }
            group.addTask { return .notes(["(Notes provider disabled due to hung process)"]) }
            group.addTask {
                do {
                    return .health(try await self.whoopProvider.fetchRecovery(for: date))
                } catch {
                    print("⚠️ Health fetch failed: \(error)")
                    return .health("No data")
                }
            }
            group.addTask {
                do {
                    return .github(try await self.githubProvider.fetchActivity(for: date))
                } catch {
                    print("⚠️ Github fetch failed: \(error)")
                    return .github([])
                }
            }

            var imessageData: [String] = []
            var whatsappData: [String] = []
            var gmailData: [String] = []
            var calendarData: [String] = []
            var notesData: [String] = []
            var healthData: [String] = []
            var githubData: [String] = []

            for try await result in group {
                switch result {
                case .imessage(let data): imessageData = data
                case .whatsapp(let data): whatsappData = data
                case .gmail(let data): gmailData = data
                case .calendar(let data): calendarData = data
                case .notes(let data): notesData = data
                case .health(let data): healthData = [data]
                case .github(let data): githubData = data
                }
            }

            print("🔍 Researching meeting entities...")
            var enrichedMeetings = calendarData
            for meeting in calendarData {
                // Simple entity extraction: look for capitalized words that might be companies or names
                let entities = self.extractEntities(from: meeting)
                for entity in entities {
                    do {
                        let research = try await self.researchService.research(entity: entity)
                        enrichedMeetings.append("Research on \(entity): \(research)")
                    } catch {
                        print("⚠️ Research failed for \(entity): \(error)")
                    }
                }
            }

            print("🧠 Synthesizing brief content...")
            let rawData = """
            Date: \(DateFormatter.yyyyMMdd.string(from: date))
            Meetings: \(enrichedMeetings.joined(separator: "; "))
            Communications:
              - iMessage: \(imessageData.joined(separator: "; "))
              - WhatsApp: \(whatsappData.joined(separator: "; "))
              - Gmail: \(gmailData.joined(separator: "; "))
            Notes: \(notesData.joined(separator: "; "))
            Health: \(healthData.joined(separator: "; "))
            Development: \(githubData.joined(separator: "; "))
            """

            let summary = try await synthesisService.synthesize(data: rawData)

            var audioPath: String? = nil
            if includeVoice {
                audioPath = try await generateVoiceBrief(summary: summary, date: date)
            }

            let communications = imessageData + whatsappData + gmailData
            let relevantCommunications = communications.prefix(limit)
            
            // Generate conversation analytics
            var conversationStats: [ConversationStat]? = nil
            do {
                print("📊 Analyzing conversation activity...")
                let imessages = try await imProvider.fetchStructuredMessages(for: date, limit: limit)
                let whatsappMessages = try await whatsappProvider.fetchStructuredMessages(for: date, limit: limit)
                
                let imessageStats = await analyticsService.analyzeMessages(imessages, source: "iMessage")
                let whatsappStats = await analyticsService.analyzeMessages(whatsappMessages, source: "WhatsApp")
                
                let combinedStats = await analyticsService.combineStats([imessageStats, whatsappStats])
                conversationStats = await analyticsService.topConversations(combinedStats, limit: 10)
                
                if conversationStats?.isEmpty == false {
                    print("✅ Analyzed \(conversationStats?.count ?? 0) conversations")
                }
            } catch {
                print("⚠️ Conversation analytics failed: \(error)")
                // Continue without analytics - don't fail the entire brief
            }

            return DailyBrief(
                date: date,
                summary: summary,
                meetings: enrichedMeetings.isEmpty ? nil : enrichedMeetings,
                communications: relevantCommunications.isEmpty ? nil : Array(relevantCommunications),
                notes: notesData.isEmpty ? nil : notesData,
                health: healthData.isEmpty ? nil : healthData,
                github: githubData.isEmpty ? nil : githubData,
                audioPath: audioPath,
                conversationStats: conversationStats
            )
        }
    }

    private func extractEntities(from text: String) -> [String] {
        // Simple heuristic for names/companies: words starting with uppercase
        // In a real app, this would be more sophisticated (NLP)
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { word in
            guard word.count > 2 else { return false }
            return word.first?.isUppercase == true
        }
    }

    public func generateVoiceBrief(summary: String, date: Date) async throws -> String {
        print("🎵 Generating voice brief...")

        let apiKey = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ""
        let voiceId = ProcessInfo.processInfo.environment["ELEVENLABS_VOICE_ID"] ?? "21m00Tcm4TlvDq8ikWAM"

        guard !apiKey.isEmpty else {
            throw BriefError.missingAPIKey
        }

        let client = ElevenLabsTTSClient(apiKey: apiKey)
        let request = ElevenLabsTTSRequest(text: summary, modelId: "eleven_monolingual_v1")
        
        let audioData = try await client.synthesize(voiceId: voiceId, request: request)
        
        let outputPath = "/tmp/briefly-voice-\(DateFormatter.yyyyMMdd.string(from: date)).mp3"
        try audioData.write(to: URL(fileURLWithPath: outputPath))

        print("✅ Voice brief generated at: \(outputPath)")
        return outputPath
    }

    private enum DataSourceResult {
        case imessage([String])
        case whatsapp([String])
        case gmail([String])
        case calendar([String])
        case notes([String])
        case health(String)
        case github([String])
    }
}

public enum BriefError: Error {
    case missingAPIKey
    case voiceGenerationFailed(String)
}
