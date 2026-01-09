# Briefly 📋 — Daily briefing CLI + MCP server

![Briefly Logo](assets/logo.svg)

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white&style=flat-square)](https://swift.org/)
[![macOS 13+](https://img.shields.io/badge/macOS-13+-0078d7?logo=apple&logoColor=white&style=flat-square)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-ffd60a?style=flat-square)](https://opensource.org/licenses/MIT)
[![MCP Server](https://img.shields.io/badge/MCP-Server-2ea44f?style=flat-square)](https://modelcontextprotocol.io/)

Your daily briefing companion that synthesizes information from communication channels, calendar, and health data into concise summaries with optional voice output.

## What you get

| Feature | Description |
|---------|-------------|
| **Daily Brief** | Comprehensive summary from all data sources |
| **Voice Output** | ElevenLabs TTS for audio briefings |
| **Multiple Sources** | iMessage, WhatsApp, Gmail, Calendar, Notes, Whoop |
| **MCP Server** | All features exposed as MCP tools for AI agents |

## Install

```bash
# Clone and build
git clone https://github.com/RyanLisse/briefly.git
cd briefly
swift build -c release

# Install to PATH
cp .build/release/briefly /usr/local/bin/briefly
```

## Quick start

```bash
# Today's brief
briefly brief

# Specific date
briefly brief --date 2026-01-09

# With voice output
briefly brief --voice

# JSON output
briefly brief --json

# Limit items per source
briefly brief --limit 25
```

| Command | Key flags | What it does |
|---------|-----------|--------------|
| `brief` | `--date`, `--voice`, `--json`, `--limit` | Generate daily briefing |
| `pulse` | `--json` | Quick status check |
| `setup` | - | Check and install dependencies |
| `mcp serve` | - | Start MCP server |

## Data Sources

| Source | Description |
|--------|-------------|
| 📱 **iMessage** | Recent conversations |
| 💬 **WhatsApp** | Message history |
| 📧 **Gmail** | Important emails |
| 📅 **Calendar** | Today's meetings |
| 📝 **Notes** | Recent notes |
| 💪 **Whoop** | Health metrics and workouts |
| 🔍 **Brave Search** | Web research |
| 🐙 **GitHub** | Activity and notifications |

## MCP Server

Start the MCP server for AI agent integration:

```bash
briefly mcp serve
```

### MCP Tools

| Tool | Description |
|------|-------------|
| `generate_daily_brief` | Generate comprehensive daily briefing |
| `generate_voice_brief` | Convert text to speech |

### Claude Desktop Config

```json
{
  "mcpServers": {
    "briefly": {
      "command": "briefly",
      "args": ["mcp", "serve"]
    }
  }
}
```

## Architecture

Follows the [Peekaboo](https://github.com/steipete/Peekaboo) architecture standard:

```
Sources/
├── Core/           # BrieflyCore - framework-agnostic library
│   ├── Models/     # Message, BriefOutput
│   ├── Providers/  # DataProvider protocol + 8 implementations
│   └── Services/   # BriefService, SynthesisService, etc.
├── CLI/            # BrieflyCLI - ArgumentParser commands
│   └── Commands/   # Brief, Pulse, Setup, MCP
├── MCP/            # BrieflyMCP - MCP server with handler pattern
│   └── Handlers/   # ToolHandler
└── Executable/     # Main entry point
```

## Requirements

- **macOS 13+** (Ventura or later)
- **Swift 6.0+** toolchain
- **ElevenLabs API key** (for voice generation)

## Configuration

```bash
# ElevenLabs for voice
export ELEVENLABS_API_KEY="your-api-key"

# Gmail (optional)
export GMAIL_CLIENT_ID="your-client-id"
export GMAIL_CLIENT_SECRET="your-client-secret"
```

## Development

```bash
# Build
swift build

# Run CLI
swift run briefly --help

# Test
swift test
```

### Swift 6 Settings

All targets use strict concurrency:

```swift
.enableExperimentalFeature("StrictConcurrency")
.enableUpcomingFeature("ExistentialAny")
.enableUpcomingFeature("NonisolatedNonsendingByDefault")
```

## License

MIT
