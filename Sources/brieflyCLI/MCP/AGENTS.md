# MCP DOMAIN KNOWLEDGE

**Generated:** 2026-01-06
**Scope:** MCP Server Implementation

## OVERVIEW
Implementation of the Model Context Protocol (MCP) server that exposes `briefly` functionality to LLMs.

## STRUCTURE
```
.
└── brieflyMCPServer.swift  # Server actor, tool definitions, and request routing
```

## WHERE TO LOOK
| Component | Location | Role |
|-----------|----------|------|
| **Tool Definitions** | `brieflyMCPServer.init()` | JSON Schema definitions for tools |
| **Server Lifecycle** | `brieflyMCPServer.run()` | Server initialization and Stdio transport |
| **Request Routing** | `handleToolCall` | Switches between different tool implementations |
| **Brief Generation** | `handleGenerateBrief` | Orchestrates BriefService for the `generate_daily_brief` tool |

## CONVENTIONS
- **Protocol**: Uses the Model Context Protocol over Standard I/O (Stdio).
- **Service Injection**: `BriefService` is instantiated within handlers to ensure thread safety and fresh state.
- **Output Formatting**: Tool results are primarily Markdown strings optimized for LLM consumption.
- **Error Handling**: Uses `CallTool.Result` with error descriptions to provide graceful failure feedback to the LLM.

## ANTI-PATTERNS
- **Fat Handlers**: Do not put business logic here. All data fetching must live in `Services`.
- **Sync Operations**: Never perform synchronous I/O or long-running tasks that block the actor.
- **Raw Data Dumps**: Avoid returning large JSON blobs. Prefer curated, summarized Markdown.
- **Stateful Tools**: Tools should be idempotent where possible; avoid relying on server actor state.

## AVAILABLE TOOLS
- `generate_daily_brief`: Aggregates calendar, comms, and health data into a Markdown report.
- `generate_voice_brief`: (Placeholder) Converts text to speech via ElevenLabs integration.
