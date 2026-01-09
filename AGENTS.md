READ ~/Developer/agent-scripts/AGENTS.MD BEFORE ANYTHING (skip if missing)

# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-06
**Branch:** main

## OVERVIEW
`briefly` is a Swift-based tool that generates daily briefings by synthesizing data from communication (iMessage, WhatsApp, Gmail) and productivity (Calendar, Notes) sources. It operates as both a CLI tool and an MCP (Model Context Protocol) server.

## STRUCTURE
```
.
├── Package.swift           # Swift Package Manager config
├── Sources/
│   ├── brieflyExec/        # Executable entry point (shim)
│   └── brieflyCLI/         # Core library
│       ├── briefly.swift   # CLI configuration
│       ├── Commands/       # CLI command definitions
│       ├── Services/       # Business logic & data orchestration
│       └── MCP/            # MCP Server implementation
└── Tests/
    └── brieflyTests/       # Unit tests
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **CLI Commands** | `Sources/brieflyCLI/Commands/` | Argument parsing, subcommands |
| **Core Logic** | `Sources/brieflyCLI/Services/BriefService.swift` | Data aggregation orchestration |
| **MCP Server** | `Sources/brieflyCLI/MCP/brieflyMCPServer.swift` | MCP tools (`generate_daily_brief`) |
| **Data Sources** | `Sources/brieflyCLI/Services/` | Service mocks (IM, WhatsApp, etc.) |
| **Tests** | `Tests/brieflyTests/` | XCTest suites |

## CODE MAP
| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `briefly` | Struct | `brieflyCLI/briefly.swift` | CLI Entry Point (`AsyncParsableCommand`) |
| `BriefService` | Actor | `brieflyCLI/Services/BriefService.swift` | Central Orchestrator |
| `brieflyMCPServer` | Actor | `brieflyCLI/MCP/brieflyMCPServer.swift` | MCP Server Implementation |
| `BriefCommand` | Struct | `brieflyCLI/Commands/BriefCommand.swift` | `brief` subcommand |
| `MCPCommand` | Struct | `brieflyCLI/Commands/MCPCommand.swift` | `mcp` subcommand |

## CONVENTIONS
- **Swift Version**: 6.2
- **Concurrency**: Extensive use of `async/await` and `actor` for thread safety and parallel data fetching.
- **Testing**: Standard `XCTest`. `@testable import brieflyCLI` used for internal testing.
- **Architecture**: Separation of Concerns: Executable -> Library -> [Commands, Services, MCP].

## ANTI-PATTERNS (THIS PROJECT)
- **Blocking Code**: Avoid synchronous file I/O or heavy computation on the main thread; use `async` contexts.
- **Direct implementation in Commands**: Delegate business logic to `Services`, keep `Commands` for parsing/glue.

## NOTES
- **Mocked Services**: Currently, most services (IM, WhatsApp, Gmail) are implemented as stubs/placeholders returning empty data.
- **Voice Generation**: `ElevenLabsKit` integration is present but uses a placeholder for actual audio generation.
- **Platform**: Explicitly targets `macOS(.v26)`.

## COMMANDS
```bash
# Build
swift build

# Run CLI
swift run briefly brief

# Run MCP Server
swift run briefly mcp

# Test
swift test
```
