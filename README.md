# Briefly

![Briefly Logo](assets/logo.svg)

**Briefly** - Your daily briefing companion that synthesizes information from communication channels, calendar, and health data into concise text summaries with optional voice output.

*Generate comprehensive daily briefings from iMessage, WhatsApp, Gmail, Calendar, Reminders, Notes, and Whoop health data.*

## Requirements

- macOS 26+ (Tahoe)
- Swift 6.2+
- ElevenLabs API key (for voice generation)

## Installation

### From Source

```bash
git clone https://github.com/steipete/briefly.git
cd briefly
swift build -c release
cp .build/release/briefly /usr/local/bin/
```

## CLI Usage

### Generate Daily Brief

```bash
briefly brief                           # Today's brief
briefly brief --date 2026-01-05         # Specific date
briefly brief --voice                   # Include voice output
briefly brief --limit 25                # Limit items per source
briefly brief --json                    # JSON output
```

### MCP Server Setup

Add to your Claude Desktop config:

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

### Available MCP Tools

| Tool | Description |
|------|-------------|
| `generate_daily_brief` | Generate comprehensive daily briefing |
| `generate_voice_brief` | Convert text to speech |

## Data Sources

Briefly collects from:
- 📱 **iMessage** - Recent conversations
- 💬 **WhatsApp** - Message history
- 📧 **Gmail** - Important emails
- 📅 **Calendar** - Today's meetings
- 📝 **Notes** - Recent notes and reminders
- 💪 **Whoop** - Health metrics and workouts

## Configuration

Set your ElevenLabs API key:

```bash
export ELEVENLABS_API_KEY="your-api-key-here"
```

## License

MIT License