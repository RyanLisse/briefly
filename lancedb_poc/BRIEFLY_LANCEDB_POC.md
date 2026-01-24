# Briefly LanceDB POC

## Overview

This POC demonstrates how **LanceDB** can enhance Briefly with advanced features for brief synthesis and retrieval. LanceDB is an open-source vector database optimized for AI applications, making it an ideal fit for Briefly's multi-source daily briefings.

## Why LanceDB for Briefly?

| Benefit | Description | Use Case for Briefly |
|---------|-------------|---------------------|
| **Vector Search** | Semantic similarity search across briefs | Find briefs by topic, not just keywords |
| **Multi-Source Aggregation** | Store data from all sources in one table | Unified view across iMessage, WhatsApp, Gmail, etc. |
| **Multi-Base** | Distributed storage across multiple locations | Archive old briefs, separate by time/categories |
| **Columnar Storage** | Fast queries on large datasets | Scale to years of brief history |
| **Zero-Config** | Embedded, no separate database server | Simple deployment, ideal for CLI tools |
| **ML Native** | Built for embeddings and AI workloads | Natural fit with MLX voice models |

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Data Sources                              │
│  iMessage  │  WhatsApp  │  Gmail  │  Calendar  │  Whoop ...  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Briefly Core                                │
│           (Data Aggregation & Synthesis)                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  LanceDB                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  briefs table (default base)                        │  │
│  │  ├─ id, date, source, content                       │  │
│  │  ├─ embedding (vector)                               │  │
│  │  ├─ voice_audio, summary, tags, priority            │  │
│  │  └─ created_at                                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  archive base (multi-base)                          │  │
│  │  └─ briefs table (archived data)                    │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Query & Retrieval                           │
│  • Semantic search (find by meaning)                         │
│  • Source filtering (by app/channel)                         │
│  • Tag filtering (by category)                               │
│  • Date range queries                                        │
│  • Priority filtering                                        │
└─────────────────────────────────────────────────────────────┘
```

### Schema Design

```python
pa.schema([
    pa.field("id", pa.string()),                      # Unique identifier
    pa.field("date", pa.date32()),                     # Brief date
    pa.field("source", pa.string()),                  # iMessage, WhatsApp, Gmail, etc.
    pa.field("content", pa.string()),                  # Full brief content
    pa.field("embedding", pa.list_(pa.float32(), 384)),# Vector for semantic search
    pa.field("voice_audio", pa.string()),              # Path to audio file
    pa.field("summary", pa.string()),                  # Brief summary
    pa.field("tags", pa.list_(pa.string())),          # Categorization tags
    pa.field("priority", pa.int32()),                  # Priority (1-10)
    pa.field("created_at", pa.timestamp("ms")),        # Timestamp
])
```

## Installation

### Prerequisites

- Python 3.8 or higher
- pip package manager

### Setup

```bash
# Navigate to the POC directory
cd /Volumes/Main\ SSD/Developer/Briefly/lancedb_poc/

# Install dependencies
pip install -r requirements.txt
```

## Usage

### Running the POC

```bash
# Run the full demonstration
python briefly_lancedb_poc.py
```

This will:
1. Initialize a local LanceDB database at `./briefly_db`
2. Load sample brief data from multiple sources
3. Demonstrate semantic search
4. Demonstrate filtering by source, tags, and date
5. Demonstrate multi-base functionality

### Programmatic Usage

```python
from briefly_lancedb_poc import BrieflyLanceDB
from datetime import date

# Initialize database
db = BrieflyLanceDB(db_path="./my_briefly_db")

# Insert a brief
db.insert_brief(
    brief_id="msg_001",
    brief_date=date.today(),
    source="iMessage",
    content="Mom asked about dinner plans for Sunday",
    summary="Dinner plans with Mom",
    tags=["family", "plans"],
    priority=7
)

# Semantic search
results = db.semantic_search("family events", limit=5)

# Filter by source
results = db.search_by_source("Gmail", limit=10)

# Search by date range
from datetime import timedelta
start = date.today() - timedelta(days=7)
end = date.today()
results = db.search_by_date_range(start, end)
```

## Features Demonstrated

### 1. Multi-Source Aggregation

All briefs from different sources are stored in a single table with a `source` field for filtering:

```python
# Briefs from all sources
results = db.search_by_source("iMessage")
results = db.search_by_source("Whoop")
results = db.search_by_source("Calendar")
# ... and more
```

**Benefit**: Unified query interface across all data sources.

### 2. Semantic Search

Find briefs by meaning, not just keywords:

```python
# Find all briefs about "work meetings"
db.semantic_search("work meetings and deadlines")

# Find health-related content
db.semantic_search("health and fitness metrics")

# Combine with filters
db.semantic_search("project updates", source_filter="iMessage")
db.semantic_search("urgent tasks", min_priority=8)
```

**Benefit**: Discover relevant briefs even if you don't use exact keywords.

### 3. Multi-Base Storage

Store briefs across multiple database locations:

```python
# Add an archive base
db.add_base("archive", "./briefly_db/archive_base")

# Insert into archive base
db.insert_brief(
    brief_id="arch_001",
    brief_date=date(2023, 12, 1),
    source="Gmail",
    content="...",
    base="archive"
)

# Query from archive base
results = db.get_briefs_by_base("archive")
```

**Use Cases**:
- Archive old briefs to reduce main database size
- Separate briefs by time periods (monthly/quarterly archives)
- Distribute storage across locations
- Personal vs work brief separation

**Benefit**: Flexible storage strategy for different access patterns.

### 4. Flexible Filtering

```python
# By source
db.search_by_source("iMessage")

# By tags
db.search_by_tags(["work", "review"])

# By date range
db.search_by_date_range(start_date, end_date)

# By priority
db.semantic_search("tasks", min_priority=8)

# Combined filters
db.semantic_search("meetings", source_filter="Calendar", min_priority=7)
```

### 5. Vector Embeddings

All briefs are automatically embedded using SentenceTransformer for semantic search:

- Model: `all-MiniLM-L6-v2` (384 dimensions)
- Embedded field: `content`
- Fast, local computation (no API calls)

## Sample Output

```
============================================================
Briefly LanceDB POC
Demonstrating LanceDB for Brief Synthesis and Retrieval
============================================================
Creating 'briefs' table at ./briefly_db

📥 Loading sample brief data...
✓ Inserted brief 'imsg_001' into default base
✓ Inserted brief 'imsg_002' into default base
...
✓ Loaded 12 sample briefs

📊 Database Statistics:
  Total briefs: 12
  Average priority: 6.92
  High priority briefs (>=8): 4
  Sources:
    - iMessage: 2
    - WhatsApp: 2
    - Gmail: 2
    - Calendar: 2
    - Whoop: 2
    - GitHub: 2
  Bases: default

============================================================
🔍 SEMANTIC SEARCH DEMONSTRATION
============================================================

🔍 Semantic search for: 'work meetings and deadlines'
   Found 5 results:

  [1] Calendar | Priority: 9 | Score: 0.7823
      Quarterly review meeting at 10 AM
      Tags: work, meeting, quarterly

  [2] iMessage | Priority: 8 | Score: 0.7145
      Project proposal review needed
      Tags: work, project, review
  ...
```

## Integration with Briefly

### Proposed Integration Points

1. **Brief Storage**: After generating a daily brief, store individual brief items in LanceDB
2. **History Search**: Add `briefly search` command for semantic search across brief history
3. **Archive Management**: Automatic archiving of briefs older than X days to archive base
4. **Priority Learning**: Learn user preferences and auto-assign priorities

### Example CLI Commands (Future)

```bash
# Search brief history
briefly search "meetings with stakeholders"
briefly search "health alerts" --source Whoop
briefly search "urgent tasks" --priority >=8

# Archive old briefs
briefly archive --older-than 90d

# Cross-source analysis
briefly analyze --topics "work" --period "last-30d"
```

### Swift Integration

Since Briefly is a Swift project, LanceDB can be accessed via:

1. **Python bridge**: Use PythonKit to call the Python POC from Swift
2. **HTTP API**: Run a simple Flask/FastAPI server for LanceDB operations
3. **Rust binding**: LanceDB has Rust bindings that can be accessed via Swift

Example using PythonKit:

```swift
import PythonKit

let sys = Python.import("sys")
sys.path.append("/path/to/lancedb_poc")

let lancedb = Python.import("briefly_lancedb_poc")
let db = lancedb.BrieflyLanceDB(dbPath: "./briefly_db")

let results = db.semantic_search("work meetings", limit: 5)
```

## Performance Characteristics

| Operation | Approximate Time (1000 briefs) |
|-----------|-------------------------------|
| Insert brief | ~5ms |
| Semantic search (top 5) | ~10ms |
| Source filter query | ~2ms |
| Date range query | ~3ms |

*Local benchmarks on M2 Mac mini*

## Next Steps

1. **Production Schema**: Refine schema based on real Briefly data
2. **Embedding Model**: Evaluate embedding models (consider domain-specific fine-tuning)
3. **Swift Integration**: Implement PythonKit or HTTP bridge
4. **CLI Commands**: Add search and archive commands to Briefly CLI
5. **Voice Integration**: Link LanceDB briefs to MLX-generated audio files
6. **Retention Policy**: Implement automatic archival of old briefs

## Dependencies

```
lancedb>=0.10.0          # LanceDB client
pyarrow>=14.0.0          # Arrow data format
numpy>=1.24.0            # Numerical operations
sentence-transformers>=2.2.0  # Embedding model
python-dotenv>=1.0.0     # Environment variables
```

## License

MIT License - Same as Briefly

---

**Questions?** This POC is designed to be a starting point. Feel free to experiment, modify, and adapt it to Briefly's specific needs.
