import Foundation

public actor EntityCache {
    private let cacheURL: URL
    private var cache: [String: String]

    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent(".briefly/entity_cache.json")
        self.cacheURL = url
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.cache = decoded
        } else {
            self.cache = [:]
        }
    }

    public func get(for entity: String) -> String? {
        return cache[entity]
    }

    public func set(_ result: String, for entity: String) {
        cache[entity] = result
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(cache) {
            try? data.write(to: cacheURL)
        }
    }
}
