// Sources/brieflyCLI/Services/BriefService.swift
import Foundation
import ElevenLabsKit

public struct DailyBrief: Codable {
    public let date: Date
    public let meetings: [String]?
    public let communications: [String]?
    public let notes: [String]?
    public let health: [String]?
    public let audioPath: String?

    public init(date: Date, meetings: [String]? = nil, communications: [String]? = nil,
                notes: [String]? = nil, health: [String]? = nil, audioPath: String? = nil) {
        self.date = date
        self.meetings = meetings
        self.communications = communications
        self.notes = notes
        self.health = health
        self.audioPath = audioPath
    }
}

public struct BriefService {
    public init() {}

    public func generateBrief(for date: Date, limit: Int = 50, includeVoice: Bool = false) async throws -> DailyBrief {
        print("📊 Gathering data from all sources...")

        // Create services locally to avoid data race issues
        let imessageService = IMService()
        let whatsappService = WhatsAppService()
        let gmailService = GmailService()
        let calendarService = CalendarService()
        let notesService = NotesService()
        let whoopService = WhoopService()

        // Gather data from all sources in parallel
        async let imessageTask = imessageService.fetchMessages(for: date, limit: limit)
        async let whatsappTask = whatsappService.fetchMessages(for: date, limit: limit)
        async let gmailTask = gmailService.fetchMessages(for: date, limit: limit)
        async let calendarTask = calendarService.fetchEvents(for: date)
        async let notesTask = notesService.fetchNotesAndReminders(for: date, limit: limit)
        async let whoopTask = whoopService.fetchHealthData(for: date)

        // Wait for all data to be collected
        let (imessageData, whatsappData, gmailData, calendarData, notesData, whoopData) =
            try await (imessageTask, whatsappTask, gmailTask, calendarTask, notesTask, whoopTask)

        print("🧠 Synthesizing brief content...")

        // Combine and filter communications
        var communications: [String] = []
        communications.append(contentsOf: imessageData)
        communications.append(contentsOf: whatsappData)
        communications.append(contentsOf: gmailData)

        // Apply relevance filtering (simplified - in real implementation would use LLM)
        let relevantCommunications = communications.filter { !$0.isEmpty }.prefix(limit)

        var audioPath: String? = nil
        if includeVoice && !communications.isEmpty {
            audioPath = try await generateVoiceBrief(
                meetings: calendarData,
                communications: Array(relevantCommunications),
                notes: notesData,
                health: whoopData,
                date: date
            )
        }

        return DailyBrief(
            date: date,
            meetings: calendarData.isEmpty ? nil : calendarData,
            communications: relevantCommunications.isEmpty ? nil : Array(relevantCommunications),
            notes: notesData.isEmpty ? nil : notesData,
            health: whoopData.isEmpty ? nil : whoopData,
            audioPath: audioPath
        )
    }

    private func generateVoiceBrief(meetings: [String], communications: [String],
                                   notes: [String], health: [String], date: Date) async throws -> String {
        print("🎵 Generating voice brief...")

        // Create text content for voice synthesis
        var textContent = "Daily Brief for \(DateFormatter.yyyyMMdd.string(from: date)). "

        if !meetings.isEmpty {
            textContent += "Meetings: \(meetings.joined(separator: ". ")). "
        }

        if !communications.isEmpty {
            textContent += "Communications: \(communications.joined(separator: ". ")). "
        }

        if !notes.isEmpty {
            textContent += "Notes and reminders: \(notes.joined(separator: ". ")). "
        }

        if !health.isEmpty {
            textContent += "Health data: \(health.joined(separator: ". ")). "
        }

        // Use ElevenLabs to generate voice
        let apiKey = ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"] ?? ""

        guard !apiKey.isEmpty else {
            throw BriefError.missingAPIKey
        }

        // TODO: Implement ElevenLabs integration
        // For now, create a placeholder audio file path
        let outputPath = "/tmp/briefly-voice-\(DateFormatter.yyyyMMdd.string(from: date)).mp3"

        // Create a dummy file to indicate voice generation would work
        try? textContent.write(toFile: outputPath, atomically: true, encoding: .utf8)

        print("⚠️ Voice generation not yet implemented - created placeholder file")
        return outputPath
    }
}

// Service protocols and implementations would go here
// For brevity, showing simplified implementations

public protocol MessageService {
    func fetchMessages(for date: Date, limit: Int) async throws -> [String]
}

struct IMService: MessageService {
    func fetchMessages(for date: Date, limit: Int) async throws -> [String] {
        // Implementation would run AppleScript to fetch iMessages
        // For now, return empty array
        return []
    }
}

struct WhatsAppService: MessageService {
    func fetchMessages(for date: Date, limit: Int) async throws -> [String] {
        // Implementation would use wacli to fetch WhatsApp messages
        return []
    }
}

struct GmailService: MessageService {
    func fetchMessages(for date: Date, limit: Int) async throws -> [String] {
        // Implementation would use gog to fetch Gmail messages
        return []
    }
}

struct CalendarService {
    func fetchEvents(for date: Date) async throws -> [String] {
        // Implementation would use gog to fetch calendar events
        return []
    }
}

struct NotesService {
    func fetchNotesAndReminders(for date: Date, limit: Int) async throws -> [String] {
        // Implementation would use braindump to fetch notes and reminders
        return []
    }
}

struct WhoopService {
    func fetchHealthData(for date: Date) async throws -> [String] {
        // Implementation would use whoop CLI to fetch health data
        return []
    }
}

enum BriefError: Error {
    case missingAPIKey
    case voiceGenerationFailed(String)
}