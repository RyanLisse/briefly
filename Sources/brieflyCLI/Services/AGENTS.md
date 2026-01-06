# AGENTS: Services Domain

## OVERVIEW
The Services domain orchestrates data aggregation and synthesis from disparate communication and productivity sources into a coherent daily brief.

## STRUCTURE
```
.
└── BriefService.swift       # Central Orchestrator & Service Implementations
```

## WHERE TO LOOK
| Component | Role | Location |
|-----------|------|----------|
| **Orchestrator** | `BriefService` | `BriefService.swift` (main struct) |
| **Data Model** | `DailyBrief` | `BriefService.swift` (Codable struct) |
| **Messaging** | `IMService`, `WhatsAppService`, `GmailService` | `BriefService.swift` (protocol-based) |
| **Productivity** | `CalendarService`, `NotesService` | `BriefService.swift` |
| **Health** | `WhoopService` | `BriefService.swift` |

## CONVENTIONS
- **Parallel Execution**: Always use `async let` to fetch data from multiple sources concurrently to minimize latency.
- **Protocol-Oriented**: Message-based sources should conform to `MessageService` for consistent aggregation and testing.
- **Local Instantiation**: Instantiate sub-services within orchestration methods to ensure isolation and avoid actor-reentrancy or data race issues.
- **Synthesis Logic**: Keep aggregation logic in `generateBrief` and data-specific processing in specialized methods.
- **Error Handling**: Use `BriefError` to categorize failures across different external integration points.

## ANTI-PATTERNS
- **Sequential Awaiting**: Never `await` service calls one-by-one; utilize Swift concurrency for parallel fetching.
- **Stateful Services**: Avoid storing mutable state in services; they should behave as stateless data fetchers.
- **Tight Coupling**: Do not hardcode API keys; retrieve them from the environment or configuration.
- **CLI Logic in Services**: Services should return data models (`DailyBrief`), leaving presentation concerns to the CLI or MCP layers.
