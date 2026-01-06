# Briefly Redesign Phase 2: Peekaboo-Inspired Providers

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the core "Provider" abstraction and the first set of real data providers using the `ShellExecutor` and `DependencyManager`.

**Architecture:** We will define a `CLIProvider` protocol, implement binary verification in `DependencyManager`, and create the `WhatsAppProvider` and `GmailProvider` using the new architecture.

**Tech Stack:** Swift 6.2, Foundation (Process), ShellExecutor actor.

---

### Task 4: Dependency Verification Logic

**Files:**
- Modify: `Sources/brieflyCLI/Services/DependencyManager.swift`
- Test: `Tests/brieflyTests/DependencyManagerTests.swift`

**Step 1: Write the failing test**

```swift
func testDependencyVerification() async {
    let manager = DependencyManager.shared
    let isEchoPresent = await manager.verifyPresence(of: "echo")
    XCTAssertTrue(isEchoPresent)
    
    let isFakePresent = await manager.verifyPresence(of: "nonexistent-binary-xyz")
    XCTAssertFalse(isFakePresent)
}
```

**Step 2: Implement verification logic**

Add `verifyPresence(of binaryName: String) async -> Bool` to `DependencyManager`. It should use `ShellExecutor` to run `which binaryName`.

---

### Task 5: Core Provider Protocol

**Files:**
- Create: `Sources/brieflyCLI/Services/Provider.swift`

**Step 1: Define the protocol**

```swift
public protocol Provider: Sendable {
    var id: String { get }
    var dependencyId: String { get }
    func checkStatus() async throws -> ProviderStatus
}

public enum ProviderStatus: Sendable {
    case ready
    case missingDependency
    case unauthenticated(instructions: String)
}
```

---

### Task 6: WhatsAppProvider Implementation

**Files:**
- Create: `Sources/brieflyCLI/Services/WhatsAppProvider.swift`
- Test: `Tests/brieflyTests/WhatsAppProviderTests.swift`

**Step 1: Write the implementation**

Use `wacli` to fetch messages.

---

### Task 7: GmailProvider Implementation

**Files:**
- Create: `Sources/brieflyCLI/Services/GmailProvider.swift`

**Step 1: Write the implementation**

Use `gog gmail search` to fetch unread emails.
