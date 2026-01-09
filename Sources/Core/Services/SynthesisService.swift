import Foundation

public actor SynthesisService {
    private let apiKey: String
    private let session = URLSession.shared
    
    public init() {
        self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
    }
    
    public func synthesize(data: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw SynthesisError.missingAPIKey
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        You are an expert personal assistant. Synthesize the following raw data into a concise, professional, and actionable daily brief.
        Focus on:
        1. Important communications (iMessage, WhatsApp, Gmail).
        2. Meeting preparations (Calendar).
        3. Relevant health metrics (Whoop).
        4. Key notes and reminders.
        
        Raw Data:
        \(data)
        
        Format the output in clean Markdown. Be concise.
        """
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": "You are a helpful daily briefing assistant."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SynthesisError.apiError(errorBody)
        }
        
        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        return result.choices.first?.message.content ?? ""
    }
}

public enum SynthesisError: Error {
    case missingAPIKey
    case apiError(String)
}

private struct ChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
