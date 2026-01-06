# CORE LIBRARY KNOWLEDGE BASE (Sources/brieflyCLI)

**Generated:** 2026-01-06

## OVERVIEW
The core implementation of `briefly`, housing CLI routing, business logic orchestration, and the MCP server interface.

## STRUCTURE
```
.
├── briefly.swift           # CLI Root (AsyncParsableCommand)
├── Commands/               # Subcommand definitions
│   ├── BriefCommand.swift  # Data aggregation & display
│   └── MCPCommand.swift    # MCP server launcher
├── Services/               # Domain logic & Data Fetching
│   └── BriefService.swift  # Core orchestrator and service mocks
└── MCP/                    # Model Context Protocol
    └── brieflyMCPServer.swift # Tool definitions and handlers
```

## WHERE TO LOOK
| Component | Responsibility | Primary File |
|-----------|----------------|--------------|
| **CLI Routing** | Manages subcommands and versioning | `briefly.swift` |
| **Brief Synthesis** | Parallel data aggregation from all sources | `Services/BriefService.swift` |
| **MCP Tools** | Schema definition and tool execution | `MCP/brieflyMCPServer.swift` |
| **Service Mocks** | Placeholder implementations for IM, WA, etc. | `Services/BriefService.swift` |

## CONVENTIONS
- **Parallel Execution**: Use `async let` in `BriefService` to fetch data from multiple sources concurrently.
- **Protocol-Oriented**: Data services should conform to specialized protocols (e.g., `MessageService`).
- **Dependency Scope**: Instantiate services locally within aggregation methods to avoid shared state issues.
- **Logging**: Use `Logging` framework (Label: `com.steipete.briefly.mcp`) for server-side diagnostics.
- **Shared Utils**: Use `DateFormatter` extensions (e.g., `yyyyMMdd`) for consistent date handling.

## ANTI-PATTERNS
- **Command Bloat**: Keep `BriefCommand` logic restricted to parsing; delegate execution to `BriefService`.
- **Mutable Global State**: Avoid global singletons for services; pass instances or initialize per-request.
- **Blocking Threads**: Never perform blocking I/O on async contexts; use appropriate Swift concurrency patterns.

## MCP TOOLS
- `generate_daily_brief`: Synthesizes calendar, messages, and health data.
- `generate_voice_brief`: Converts text briefings into speech via ElevenLabs.

---
*Note: This knowledge base focuses on the internal mechanics of the CLI library. For high-level project context, see the root AGENTS.md.*
