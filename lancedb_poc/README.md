# Briefly LanceDB POC

A proof-of-concept demonstrating LanceDB integration for the Briefly daily briefing CLI tool.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run the demonstration
python briefly_lancedb_poc.py
```

## What This Demonstrates

- **Multi-source aggregation**: Store briefs from iMessage, WhatsApp, Gmail, Calendar, Whoop, GitHub, LinkedIn in one place
- **Semantic search**: Find briefs by meaning across all sources
- **Multi-base support**: Distribute briefs across multiple storage locations
- **Flexible filtering**: By source, tags, date range, and priority

## Files

- `briefly_lancedb_poc.py` - Main POC script with demonstrations
- `requirements.txt` - Python dependencies
- `BRIEFLY_LANCEDB_POC.md` - Full documentation
- `README.md` - This file

## Database Location

After running the POC, the LanceDB database is created at:
```
./briefly_db/
```

## Learn More

See [BRIEFLY_LANCEDB_POC.md](BRIEFLY_LANCEDB_POC.md) for detailed documentation.
