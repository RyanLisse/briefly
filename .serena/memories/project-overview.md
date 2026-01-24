briefly is a Swift-based CLI tool that generates daily briefings by synthesizing data from communication (iMessage, WhatsApp, Gmail) and productivity (Calendar, Notes) sources. It operates as both a CLI tool and MCP server, using local MLX voice models via GabGab package for private and efficient voice synthesis.

Key components:
- Core: Business logic & data providers
- CLI: ArgumentParser commands  
- MCP: MCP Server implementation
- Executable: Main entry point

Built with Swift 6.0, extensive async/await concurrency, actor isolation for thread safety. Architecture follows Peekaboo standard. Platform targets macOS(.v26).

Dependencies: GabGab (local submodule for MLX voice), SwiftPM package management.

Commands: swift build, swift run briefly brief, swift run briefly mcp, swift test