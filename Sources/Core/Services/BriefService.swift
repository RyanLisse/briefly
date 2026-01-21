import Foundation

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
    private let healthKitProvider = HealthKitProvider()
    private let githubProvider = GithubProvider()
    private let birdProvider = BirdProvider()
    private let linkedinProvider = LinkedInProvider()
    private let calyProvider = CalyProvider()
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
        includeVoice: Bool = false,
        voiceConfig: VoiceConfig = .fromEnvironment()
    ) async throws -> (today: DailyBrief, yesterday: DailyBrief?) {
        let todayBrief = try await generateBrief(
            for: date,
            limit: limit,
            includeVoice: includeVoice,
            voiceConfig: voiceConfig
        )
        
        var yesterdayBrief: DailyBrief? = nil
        if includeYesterday {
            let calendar = Calendar.current
            if let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: date) {
                yesterdayBrief = try await generateBrief(
                    for: yesterdayDate,
                    limit: limit,
                    includeVoice: false,
                    voiceConfig: voiceConfig
                )
            }
        }
        
        return (today: todayBrief, yesterday: yesterdayBrief)
    }
    
    public func generateBrief(
        for date: Date,
        limit: Int = 50,
        includeVoice: Bool = false,
        voiceConfig: VoiceConfig = .fromEnvironment()
    ) async throws -> DailyBrief {
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
            group.addTask {
                do {
                    return .notes(try await self.notesProvider.fetchNotes(modifiedAfter: date))
                } catch {
                    print("⚠️ Notes fetch failed: \(error)")
                    return .notes([])
                }
            }
            group.addTask {
                do {
                    let whoopData = try await self.whoopProvider.fetchRecovery(for: date)
                    return .health([whoopData])
                } catch {
                    print("⚠️ Whoop fetch failed: \(error)")
                    return .health([])
                }
            }
            group.addTask {
                do {
                    let healthKitData = try await self.healthKitProvider.fetchData(for: date)
                    return .health([healthKitData])
                } catch {
                    print("⚠️ HealthKit fetch failed: \(error)")
                    return .health([])
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
            group.addTask {
                do {
                    return .bird(try await self.birdProvider.fetchActivity(for: date, limit: limit))
                } catch {
                    print("⚠️ Bird fetch failed: \(error)")
                    return .bird([])
                }
            }
            group.addTask {
                do {
                    return .linkedin(try await self.linkedinProvider.fetchActivity(for: date, limit: limit))
                } catch {
                    print("⚠️ LinkedIn fetch failed: \(error)")
                    return .linkedin([])
                }
            }
            group.addTask {
                do {
                    return .caly(try await self.calyProvider.fetchEvents(for: date, limit: limit))
                } catch {
                    print("⚠️ Caly fetch failed: \(error)")
                    return .caly([])
                }
            }

            var imessageData: [String] = []
            var whatsappData: [String] = []
            var gmailData: [String] = []
            var calendarData: [String] = []
            var notesData: [String] = []
            var healthData: [String] = []
            var githubData: [String] = []
            var birdData: [String] = []
            var linkedinData: [String] = []
            var calyData: [String] = []

            for try await result in group {
                switch result {
                case .imessage(let data): imessageData = data
                case .whatsapp(let data): whatsappData = data
                case .gmail(let data): gmailData = data
                case .calendar(let data): calendarData = data
                case .notes(let data): notesData = data
                case .health(let data): healthData.append(contentsOf: data)
                case .github(let data): githubData = data
                case .bird(let data): birdData = data
                case .linkedin(let data): linkedinData = data
                case .caly(let data): calyData = data
                }
            }

            print("🔍 Researching meeting entities...")
            var enrichedMeetings = calendarData + calyData
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
            Social:
              - X/Twitter: \(birdData.joined(separator: "; "))
              - LinkedIn: \(linkedinData.joined(separator: "; "))
            """

            let summary = try await synthesisService.synthesize(data: rawData)

            let shouldGenerateVoice = shouldGenerateVoice(includeVoice: includeVoice, voiceConfig: voiceConfig)
            var audioPath: String? = nil
            if shouldGenerateVoice {
                audioPath = try await generateVoiceBrief(summary: summary, date: date, voiceConfig: voiceConfig)
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

    public func generateVoiceBrief(summary: String, date: Date, voiceConfig: VoiceConfig) async throws -> String {
        print("🎵 Generating voice brief...")

        let smartTurn = SmartTurnAnalyzer()
        await smartTurn.waitForTurnCompletion()

        let outputPath = "/tmp/briefly-voice-\(DateFormatter.yyyyMMdd.string(from: date)).mp3"
        let outputURL = URL(fileURLWithPath: outputPath)

        let engine = await VoiceEngineFactory.resolveEngine(config: voiceConfig)
        let generation = try await engine.synthesize(text: summary, profile: voiceConfig.profile, outputURL: outputURL)

        FileLogger.appendLine(
            "voice_engine=\(generation.engine.rawValue) profile=\(generation.profile.rawValue) duration=\(generation.duration)",
            to: "voice-engine.log"
        )

        print("✅ Voice brief generated at: \(outputPath)")
        return outputPath
    }

    private func shouldGenerateVoice(includeVoice: Bool, voiceConfig: VoiceConfig) -> Bool {
        switch voiceConfig.voiceMode {
        case .always:
            return true
        case .never:
            return false
        case .auto:
            return includeVoice
        }
    }

    private enum DataSourceResult {
        case imessage([String])
        case whatsapp([String])
        case gmail([String])
        case calendar([String])
        case notes([String])
        case health([String])
        case github([String])
        case bird([String])
        case linkedin([String])
        case caly([String])
    }
}

public enum BriefError: Error {
    case voiceGenerationFailed(String)
}
