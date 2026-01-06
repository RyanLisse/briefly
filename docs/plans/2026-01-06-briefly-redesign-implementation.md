# Briefly Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform `briefly` into a robust, Peekaboo-inspired CLI orchestration system with automated dependency management and intelligent research synthesis.

**Architecture:** We will implement a `DependencyManager` registry, a thread-safe `ShellExecutor` actor, and a `SetupCommand`. Individual services will be refactored into "Providers" that follow a Capability-Action model.

**Tech Stack:** Swift 6.2 (Strict Concurrency), ArgumentParser, Foundation (Process), ElevenLabsKit.

---

### Task 1: DependencyManager Registry

**Files:**
- Create: `Sources/brieflyCLI/Services/DependencyManager.swift`
- Test: `Tests/brieflyTests/DependencyManagerTests.swift`

**Step 1: Write the failing test**

```swift
import XCTest
@testable import brieflyCLI

final class DependencyManagerTests: XCTestCase {
    func testDependencyRegistry() {
        let manager = DependencyManager.shared
        let deps = manager.allDependencies
        XCTAssertFalse(deps.isEmpty)
        XCTAssertTrue(deps.contains(where: { $0.id == "wacli" }))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DependencyManagerTests`
Expected: FAIL (Type 'DependencyManager' not found)

**Step 3: Write minimal implementation**

```swift
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter DependencyManagerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/brieflyCLI/Services/DependencyManager.swift Tests/brieflyTests/DependencyManagerTests.swift
git commit -m "feat: add basic DependencyManager registry"
```

---

### Task 2: ShellExecutor Actor

**Files:**
- Create: `Sources/brieflyCLI/Utility/ShellExecutor.swift`
- Test: `Tests/brieflyTests/ShellExecutorTests.swift`

**Step 1: Write the failing test**

```swift
func testShellExecution() async throws {
    let executor = ShellExecutor()
    let result = try await executor.execute("echo", arguments: ["Hello"])
    XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "Hello")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ShellExecutorTests`
Expected: FAIL (Type 'ShellExecutor' not found)

**Step 3: Write minimal implementation**

```swift
import Foundation

public actor ShellExecutor {
    public func execute(_ command: String, arguments: [String] = []) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ShellExecutorTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/brieflyCLI/Utility/ShellExecutor.swift Tests/brieflyTests/ShellExecutorTests.swift
git commit -m "feat: add ShellExecutor actor for CLI calls"
```

---

### Task 3: SetupCommand Onboarding

**Files:**
- Create: `Sources/brieflyCLI/Commands/SetupCommand.swift`
- Modify: `Sources/brieflyCLI/briefly.swift`

**Step 1: Define the SetupCommand**

```swift
import ArgumentParser
import Foundation

struct SetupCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "setup", abstract: "Check and install dependencies")
    
    func run() async throws {
        print("🔍 Checking dependencies...")
        // Loop and check logic here
    }
}
```

**Step 2: Register in main entry point**

Modify `Sources/brieflyCLI/briefly.swift` to include `SetupCommand.self` in `subcommands`.

**Step 3: Verify CLI presence**

Run: `swift run briefly setup`
Expected: Output "🔍 Checking dependencies..."

**Step 4: Commit**

```bash
git add Sources/brieflyCLI/Commands/SetupCommand.swift Sources/brieflyCLI/briefly.swift
git commit -m "feat: add setup command placeholder"
```
