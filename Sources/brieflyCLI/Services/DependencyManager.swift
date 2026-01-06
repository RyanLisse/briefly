import Foundation

public struct Dependency: Sendable {
    public let id: String
    public let binaryName: String
    public let installCommand: String
    public let description: String
}

public actor DependencyManager {
    public static let shared = DependencyManager()
    
    public let allDependencies: [Dependency] = [
        Dependency(id: "wacli", binaryName: "wacli", installCommand: "brew install wacli", description: "WhatsApp CLI"),
        Dependency(id: "gog", binaryName: "gog", installCommand: "go install github.com/st-pete/gog@latest", description: "Google Services CLI")
    ]
}
