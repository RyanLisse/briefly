import Foundation

/// Statistics for a single conversation
public struct ConversationStat: Codable, Sendable, Identifiable {
    public let id: String
    public let contact: String
    public let sent: Int
    public let received: Int
    public let total: Int
    public let sources: [String] // ["iMessage", "WhatsApp"]
    
    public init(contact: String, sent: Int, received: Int, sources: [String]) {
        self.id = contact
        self.contact = contact
        self.sent = sent
        self.received = received
        self.total = sent + received
        self.sources = sources
    }
}

/// Service to analyze and aggregate conversation statistics
public actor ConversationAnalyticsService {
    public init() {}
    
    /// Analyze messages and return conversation statistics
    /// - Parameters:
    ///   - messages: Array of messages to analyze
    ///   - source: Source identifier (e.g., "iMessage", "WhatsApp")
    /// - Returns: Array of conversation stats sorted by total message count (descending)
    public func analyzeMessages(_ messages: [Message], source: String) -> [ConversationStat] {
        var stats: [String: (sent: Int, received: Int)] = [:]
        
        for message in messages {
            let normalizedContact = MessageParser.normalizeContact(message.contact)
            
            if stats[normalizedContact] == nil {
                stats[normalizedContact] = (sent: 0, received: 0)
            }
            
            if message.isFromMe {
                stats[normalizedContact]?.sent += 1
            } else {
                stats[normalizedContact]?.received += 1
            }
        }
        
        return stats.map { contact, counts in
            ConversationStat(
                contact: contact,
                sent: counts.sent,
                received: counts.received,
                sources: [source]
            )
        }
        .sorted { $0.total > $1.total }
    }
    
    /// Combine statistics from multiple sources (e.g., iMessage + WhatsApp)
    /// - Parameter statsArrays: Array of conversation stats arrays from different sources
    /// - Returns: Combined and sorted conversation stats
    public func combineStats(_ statsArrays: [[ConversationStat]]) -> [ConversationStat] {
        var combined: [String: (sent: Int, received: Int, sources: Set<String>)] = [:]
        
        for statsArray in statsArrays {
            for stat in statsArray {
                let normalizedContact = MessageParser.normalizeContact(stat.contact)
                
                if combined[normalizedContact] == nil {
                    combined[normalizedContact] = (sent: 0, received: 0, sources: Set<String>())
                }
                
                combined[normalizedContact]?.sent += stat.sent
                combined[normalizedContact]?.received += stat.received
                combined[normalizedContact]?.sources.formUnion(stat.sources)
            }
        }
        
        return combined.map { contact, data in
            ConversationStat(
                contact: contact,
                sent: data.sent,
                received: data.received,
                sources: Array(data.sources).sorted()
            )
        }
        .sorted { $0.total > $1.total }
    }
    
    /// Get top N conversations by total message count
    /// - Parameters:
    ///   - stats: Array of conversation stats
    ///   - limit: Maximum number of conversations to return
    /// - Returns: Top N conversations
    public func topConversations(_ stats: [ConversationStat], limit: Int = 10) -> [ConversationStat] {
        return Array(stats.prefix(limit))
    }
}
