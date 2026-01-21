READ ~/Developer/agent-scripts/AGENTS.MD BEFORE ANYTHING (skip if missing)

# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-06
**Branch:** main

## OVERVIEW
`briefly` is a Swift-based tool that generates daily briefings by synthesizing data from communication (iMessage, WhatsApp, Gmail) and productivity (Calendar, Notes) sources. It operates as both a CLI tool and an MCP (Model Context Protocol) server. It uses local MLX voice models (via the `GabGab` package) for private and efficient voice synthesis.

## STRUCTURE
```
.
├── Package.swift           # Swift Package Manager config
├── Makefile                # Task runner for build/test/setup
├── Vendor/
│   └── GabGab/             # Local voice synthesis dependency
├── Sources/
│   ├── Core/               # BrieflyCore - Business logic & data providers
│   ├── CLI/                # BrieflyCLI - ArgumentParser commands
│   ├── MCP/                # BrieflyMCP - MCP Server implementation
│   └── Executable/         # Main entry point shim
└── Tests/
    └── BrieflyCoreTests/   # Unit tests
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Voice Integration** | `Sources/Core/Voice/` | MLX and ElevenLabs engines |
| **CLI Commands** | `Sources/CLI/Commands/` | Argument parsing, subcommands |
| **Core Logic** | `Sources/Core/Services/BriefService.swift` | Data aggregation orchestration |
| **MCP Server** | `Sources/MCP/BrieflyMCPServer.swift` | MCP tools (`generate_daily_brief`) |
| **Data Sources** | `Sources/Core/Providers/` | Provider implementations (IM, WhatsApp, etc.) |
| **Tests** | `Tests/BrieflyCoreTests/` | XCTest suites |

## CODE MAP
| Symbol | Type | Location | Role |
|--------|------|----------|------|
| `BrieflyCLI` | Struct | `CLI/BrieflyCLI.swift` | CLI Entry Point (`AsyncParsableCommand`) |
| `BriefService` | Actor | `Core/Services/BriefService.swift` | Central Orchestrator |
| `BrieflyMCPServer` | Actor | `MCP/BrieflyMCPServer.swift` | MCP Server Implementation |
| `BriefCommand` | Struct | `CLI/Commands/BriefCommand.swift` | `brief` subcommand |
| `MLXVoiceEngine` | Struct | `Core/Voice/MLXVoiceEngine.swift` | Local MLX voice via GabGab |

## CONVENTIONS
- **Swift Version**: 6.2
- **Concurrency**: Extensive use of `async/await` and `actor` for thread safety and parallel data fetching.
- **Architecture**: Peekaboo standard (Executable -> Library -> [Commands, Services, MCP]).
- **Voice**: Local-first via MLX. Defaults to `local` engine (Kokoro-82M/LFM 2.5).

## ANTI-PATTERNS (THIS PROJECT)
- **Blocking Code**: Avoid synchronous file I/O or heavy computation on the main thread; use `async` contexts.
- **Direct implementation in Commands**: Delegate business logic to `Core` services, keep `CLI` for parsing/glue.

## NOTES
- **Local Models**: Setup via `make setup` downloads ~1.5GB of models to `./models/`.
- **Dependency**: `GabGab` is integrated as a local submodule at `Vendor/GabGab`.
- **Platform**: Explicitly targets `macOS(.v26)`.

## TESTING
- **Framework**: Standard `XCTest`.
- **Imports**: `@testable import Core` for core test targets.

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

## ULTRAWORK MODE

Ultrabrain mode is used for complex multi-step implementations requiring parallel agent coordination and sophisticated reasoning.

### When to Use Ultrawork Mode
- Complex feature implementations spanning multiple files/modules
- Architecture decisions requiring trade-off analysis
- Multi-system integrations (like voice engines)
- Refactoring that impacts multiple components
- Performance optimization across layers

### Ultrawork Workflow Used in This Project
For the voice engine implementation, Ultrawork mode was employed with:
1. **Parallel Agent Coordination**: Explore and Librarian agents ran concurrently for codebase understanding and external library research
2. **Sophisticated Reasoning**: Oracle consulted for architecture decisions (VoiceEngine abstraction vs direct implementation)
3. **Step-by-Step Implementation**: Frontend-UI-UX-Engineer delegated for any visual components (none in this case), while handling logic directly
4. **Documentation Agent**: Document-writer used for README and plan updates
5. **Verification**: QATester agent for functionality validation (though not used in this specific implementation)

### Key Principles
- Use skills proactively when triggers match
- Delegate specialized work to appropriate agents (visual → frontend-ui-ux-engineer, docs → document-writer)
- Consult Oracle for complex decisions or when stuck
- Parallel execution for maximum throughput
- Always verify results before marking complete

### Agent Selection Criteria
| Domain | Agent | Reason |
|--------|-------|--------|
| Architecture | oracle | High-IQ reasoning for trade-offs |
| Frontend UI/UX | frontend-ui-ux-engineer | Visual/styling changes only |
| Documentation | document-writer | README, API docs, guides |
| Research/Search | explore (internal), librarian (external) | Contextual grep for codebases |
| Complex Logic | handle directly | Unless specialized domain |

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
