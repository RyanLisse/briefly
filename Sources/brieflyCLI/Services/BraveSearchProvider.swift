import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor BraveSearchProvider {
    private let apiKey: String? = ProcessInfo.processInfo.environment["BRAVE_SEARCH_API_KEY"] ?? "BSAFunl8LgX4OlQAQRZuQ6RrtzFcbDc"
    private let endpoint = "https://api.search.brave.com/res/v1/web/search"

    public init() {}

    public func search(query: String) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return "Brave Search API key not set. Set BRAVE_SEARCH_API_KEY environment variable."
        }

        guard var components = URLComponents(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "count", value: "3")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return "Unexpected response type"
        }
        
        guard httpResponse.statusCode == 200 else {
            return "Search failed with status: \(httpResponse.statusCode)"
        }

        // Parse simplified results
        struct BraveResponse: Codable {
            struct Web: Codable {
                struct Result: Codable {
                    let description: String?
                }
                let results: [Result]?
            }
            let web: Web?
        }

        do {
            let decoded = try JSONDecoder().decode(BraveResponse.self, from: data)
            let snippets = decoded.web?.results?.compactMap { $0.description }.prefix(3) ?? []
            if snippets.isEmpty {
                return "No results found for \(query)"
            }
            return snippets.joined(separator: "\n\n")
        } catch {
            return "Failed to parse Brave Search response: \(error.localizedDescription)"
        }
    }
}
