import Foundation

public actor ResearchService {
    private let searchProvider = BraveSearchProvider()
    private let cache = EntityCache()

    public init() {}

    public func research(entity: String) async throws -> String {
        if let cached = await cache.get(for: entity) {
            return cached
        }
        let result = try await searchProvider.search(query: entity)
        await cache.set(result, for: entity)
        return result
    }
}
