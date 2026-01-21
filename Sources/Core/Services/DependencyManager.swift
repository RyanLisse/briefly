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
        Dependency(id: "wacli", binaryName: "wacli", installCommand: "brew install steipete/tap/wacli", description: "WhatsApp CLI"),
        Dependency(id: "gog", binaryName: "gog", installCommand: "brew install steipete/tap/gogcli", description: "Google Services CLI"),
        Dependency(id: "imsg", binaryName: "imsg", installCommand: "brew install steipete/tap/imsg", description: "iMessage CLI"),
        Dependency(id: "braindump", binaryName: "braindump", installCommand: "cd ~/Developer/Braindump && swift build -c release && cp .build/release/braindump /usr/local/bin/", description: "Notes and Reminders CLI"),
        Dependency(id: "whoopskill", binaryName: "whoopskill", installCommand: "npm install -g whoopskill", description: "Whoop Health CLI"),
        Dependency(id: "healthsync", binaryName: "healthsync", installCommand: "cd \"/Volumes/Main SSD/Developer/ai-health-sync-ios/macOS/HealthSyncCLI\" && swift build -c release && cp .build/release/healthsync ~/.local/bin/", description: "HealthKit Sync CLI"),
        Dependency(id: "gh", binaryName: "gh", installCommand: "brew install gh", description: "GitHub CLI")
    ]

    private let executor = ShellExecutor()

    public func verifyPresence(of binaryName: String) async -> Bool {
        do {
            let result = try await executor.execute("which", arguments: [binaryName])
            return !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }
}
