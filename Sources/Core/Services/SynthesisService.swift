import Foundation

public actor SynthesisService {
    private let apiKey: String
    private let session = URLSession.shared
    
    public init() {
        self.apiKey = ProcessInfo.processInfo.environment["GOOGLE_API_KEY"] ?? ""
    }
    
    public func synthesize(data: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw SynthesisError.missingAPIKey
        }
        
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
        You are an expert personal assistant. Synthesize the following raw data into a concise, professional, and actionable daily brief.
        Focus on:
        1. Important communications (iMessage, WhatsApp, Gmail).
        2. Meeting preparations (Calendar).
        3. Relevant health metrics (Whoop).
        4. Key notes and reminders.
        5. Social media updates (X/Twitter, LinkedIn, GitHub).
        
        Raw Data:
        \(data)
        
        Format the output in clean Markdown. Be concise.
        """
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw SynthesisError.apiError(errorBody)
        }
        
        let result = try JSONDecoder().decode(GeminiResponse.self, from: responseData)
        return result.candidates.first?.content.parts.first?.text ?? ""
    }
}

public enum SynthesisError: Error {
    case missingAPIKey
    case apiError(String)
}

private struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}
