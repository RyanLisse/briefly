Key commands and workflows for briefly:

Build & Run:
- swift build (build project)
- swift run briefly brief (run CLI with brief command)
- swift run briefly mcp (start MCP server)
- swift test (run tests)

CLI Commands:
- brief: Generate daily briefing (--engine local|elevenlabs, --profile <voice>)
- benchmark: Test voice engine performance (--iterations <n>)

MCP Tools:
- generate_daily_brief: Main briefing tool (engine, profile parameters)

Workflow for development:
1. make setup (downloads 1.5GB MLX models to ./models/)
2. swift build
3. swift run briefly brief --engine local
4. For MCP: swift run briefly mcp

Testing:
- swift test (XCTest suites in Tests/BrieflyCoreTests/)
- Benchmark command for performance validation

Voice Engine Selection:
- Default: local (MLX via GabGab)
- Fallback: elevenlabs (requires API key)
- CLI flag: --engine local|elevenlabs
- Profile selection: --profile <voice_name>