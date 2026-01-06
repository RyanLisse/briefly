# TESTS KNOWLEDGE BASE

## OVERVIEW
Unit and integration tests for the `briefly` core library using XCTest.

## STRUCTURE
```
Tests/brieflyTests/
├── DailyBriefTests.swift      # Model validation and property checks
└── brieflyTests.swift         # Core service initialization and general logic
```

## WHERE TO LOOK
| Test Target | File | Description |
|-------------|------|-------------|
| **Data Models** | `DailyBriefTests.swift` | Ensures `DailyBrief` structures are correctly initialized and handled. |
| **Services** | `brieflyTests.swift` | Validates `BriefService` lifecycle and cross-component integration. |

## CONVENTIONS
- **Access Level**: Always use `@testable import brieflyCLI` to test internal logic without exposing it publicly.
- **Error Handling**: Use `throws` in test methods to allow XCTest to catch and report unexpected failures.
- **Assertions**:
    - Use `XCTAssertEqual` for value equality checks.
    - Use `XCTAssertNil` / `XCTAssertNotNil` for optional verification.
- **Naming**: Test methods must start with `test` (e.g., `testDailyBriefCreation`).

## ANTI-PATTERNS
- **Network I/O**: NEVER perform real network requests in unit tests; use mocks or stubbed service responses.
- **File System Side Effects**: Avoid writing to user directories. Use `FileManager` with temporary locations if file testing is required.
- **Global State**: Do not rely on or modify shared global state that persists between test runs.
- **Sleep/Wait**: Avoid `Thread.sleep`. Use `XCTestExpectation` for asynchronous code testing.

## COMMANDS
```bash
# Run all tests
swift test

# Run a specific test class
swift test --filter DailyBriefTests
```
