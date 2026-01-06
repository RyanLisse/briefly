import ArgumentParser
import Foundation

struct SetupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "setup",
        abstract: "Check and install dependencies",
        discussion: "Iterates through the registered dependencies and verifies their presence on the system."
    )
    
    func run() async throws {
        print("🔍 Checking dependencies...")
        let manager = DependencyManager.shared
        let dependencies = manager.allDependencies
        
        var allPresent = true
        for dep in dependencies {
            let isPresent = await manager.verifyPresence(of: dep.binaryName)
            let status = isPresent ? "✅ Present" : "❌ Missing"
            print("\(status) \(dep.id) (\(dep.binaryName)) - \(dep.description)")
            
            if !isPresent {
                allPresent = false
                print("   👉 Install with: \(dep.installCommand)")
            }
        }
        
        if allPresent {
            print("\n✅ All dependencies are present. You're ready to go!")
        } else {
            print("\n⚠️ Some dependencies are missing. Please install them to use all features.")
        }
    }
}
