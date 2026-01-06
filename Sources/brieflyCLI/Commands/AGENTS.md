# CLI COMMANDS KNOWLEDGE BASE

**Generated:** 2026-01-06
**Directory:** `Sources/brieflyCLI/Commands/`

## OVERVIEW
Implementation of the CLI interface using `swift-argument-parser`, handling user input and subcommand routing.

## STRUCTURE
- `BriefCommand.swift`: The `brief` subcommand; handles date-based data collection and briefing output.
- `MCPCommand.swift`: The `mcp` subcommand; manages the MCP server lifecycle and tool listing.
- Root entry point is in `brieflyCLI/briefly.swift` (parent directory).

## WHERE TO LOOK
| Feature | Command | File |
|---------|---------|------|
| **Daily Briefing** | `brief` | `BriefCommand.swift` |
| **MCP Server** | `mcp serve` | `MCPCommand.swift` |
| **List MCP Tools** | `mcp tools` | `MCPCommand.swift` |

## CONVENTIONS
- **Async Execution**: All primary commands implement `AsyncParsableCommand` to support `async/await` services.
- **Service Delegation**: `run()` methods must delegate business logic to `BriefService` or `brieflyMCPServer`.
- **Formatting**:
    - Use `JSONEncoder` for structured output when requested via `@Flag var json`.
    - Use `DateFormatter` extensions (defined in `BriefCommand.swift`) for standard YYYY-MM-DD parsing.
- **Help Content**: Provide detailed `abstract` and `discussion` in `CommandConfiguration`.

## ANTI-PATTERNS
- **Fat Commands**: Do not implement data fetching or synthesis logic directly in command files.
- **Synchronous Calls**: Avoid calling `sync` versions of service methods; use `async` contexts.
- **Hardcoded Strings**: Prefer using metadata and configuration properties for command help text.
