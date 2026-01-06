import Foundation

/// Unified message model for analytics
public struct Message: Codable, Sendable, Identifiable {
    public let id: String
    public let text: String?
    public let date: Date
    public let isFromMe: Bool
    public let contact: String
    public let source: MessageSource
    
    public enum MessageSource: String, Codable, Sendable {
        case iMessage
        case whatsApp
    }
    
    public init(id: String, text: String?, date: Date, isFromMe: Bool, contact: String, source: MessageSource) {
        self.id = id
        self.text = text
        self.date = date
        self.isFromMe = isFromMe
        self.contact = contact
        self.source = source
    }
}

/// iMessage JSON structure from imsg tool
struct iMessageJSON: Codable {
    let rowid: Int?
    let text: String?
    let date: Int64?
    let is_from_me: Int?
    let handle_id: Int?
    let chat_id: Int?
    let guid: String?
    
    enum CodingKeys: String, CodingKey {
        case rowid
        case text
        case date
        case is_from_me
        case handle_id
        case chat_id
        case guid
    }
}

/// WhatsApp message JSON structure from wacli tool
struct WhatsAppMessageJSON: Codable {
    let id: String?
    let text: String?
    let timestamp: Int64?
    let from: String?
    let to: String?
    let isFromMe: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case timestamp
        case from
        case to
        case isFromMe
    }
}

/// Helper to parse messages from JSON strings
public struct MessageParser {
    /// Parse iMessage JSON (newline-delimited JSON from imsg history)
    public static func parseiMessages(_ jsonStrings: [String]) -> [Message] {
        var messages: [Message] = []
        
        for jsonString in jsonStrings {
            guard let data = jsonString.data(using: .utf8) else { continue }
            
            // Try parsing as array first (multiple messages)
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for jsonDict in jsonArray {
                    if let message = parseiMessageDict(jsonDict) {
                        messages.append(message)
                    }
                }
            }
            // Try parsing as single object
            else if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = parseiMessageDict(jsonDict) {
                    messages.append(message)
                }
            }
        }
        
        return messages
    }
    
    private static func parseiMessageDict(_ dict: [String: Any]) -> Message? {
        guard let rowid = dict["rowid"] as? Int ?? dict["ROWID"] as? Int else { return nil }
        
        let text = dict["text"] as? String ?? dict["TEXT"] as? String
        let dateValue = dict["date"] as? Int64 ?? dict["DATE"] as? Int64 ?? 0
        let isFromMe = (dict["is_from_me"] as? Int ?? dict["IS_FROM_ME"] as? Int ?? 0) == 1
        let handleId = dict["handle_id"] as? Int ?? dict["HANDLE_ID"] as? Int
        
        // Convert macOS timestamp (seconds since 2001-01-01) to Date
        let macEpoch: TimeInterval = 978307200 // 2001-01-01 00:00:00 UTC
        let date = Date(timeIntervalSince1970: macEpoch + TimeInterval(dateValue / 1_000_000_000))
        
        // Use handle_id as contact identifier (will be resolved later if needed)
        let contact = handleId.map { "\($0)" } ?? "unknown"
        
        return Message(
            id: "imessage-\(rowid)",
            text: text,
            date: date,
            isFromMe: isFromMe,
            contact: contact,
            source: .iMessage
        )
    }
    
    /// Parse WhatsApp JSON (newline-delimited JSON from wacli)
    public static func parseWhatsAppMessages(_ jsonStrings: [String]) -> [Message] {
        var messages: [Message] = []
        
        for jsonString in jsonStrings {
            guard let data = jsonString.data(using: .utf8) else { continue }
            
            // Try parsing as array first
            if let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                for jsonDict in jsonArray {
                    if let message = parseWhatsAppDict(jsonDict) {
                        messages.append(message)
                    }
                }
            }
            // Try parsing as single object
            else if let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let message = parseWhatsAppDict(jsonDict) {
                    messages.append(message)
                }
            }
        }
        
        return messages
    }
    
    private static func parseWhatsAppDict(_ dict: [String: Any]) -> Message? {
        guard let id = dict["id"] as? String ?? dict["ID"] as? String else { return nil }
        
        let text = dict["text"] as? String ?? dict["TEXT"] as? String
        let timestamp = dict["timestamp"] as? Int64 ?? dict["TIMESTAMP"] as? Int64 ?? 0
        let from = dict["from"] as? String ?? dict["FROM"] as? String
        let to = dict["to"] as? String ?? dict["TO"] as? String
        let isFromMe = dict["isFromMe"] as? Bool ?? dict["is_from_me"] as? Bool ?? false
        
        // Convert timestamp (milliseconds since epoch) to Date
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        
        // Use 'from' or 'to' as contact identifier based on direction
        let contact = isFromMe ? (to ?? "unknown") : (from ?? "unknown")
        
        return Message(
            id: "whatsapp-\(id)",
            text: text,
            date: date,
            isFromMe: isFromMe,
            contact: contact,
            source: .whatsApp
        )
    }
    
    /// Normalize contact identifier (phone numbers, emails) for grouping
    public static func normalizeContact(_ contact: String) -> String {
        // Remove common phone number formatting
        let cleaned = contact
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "+", with: "")
            .lowercased()
        
        return cleaned.isEmpty ? contact : cleaned
    }
}
