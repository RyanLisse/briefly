#!/usr/bin/env python3
"""
Briefly LanceDB POC - Demonstrating LanceDB for Brief Synthesis and Retrieval

This script demonstrates how LanceDB can enhance Briefly with:
1. Multi-source aggregation in a single table
2. Semantic search across briefs
3. Multi-base support for distributed brief storage
"""

import os
import sys
from datetime import datetime, date, timedelta
from typing import List, Dict, Any, Optional
import pyarrow as pa
import lancedb
from sentence_transformers import SentenceTransformer
import numpy as np


class BrieflyLanceDB:
    """LanceDB integration for Briefly - manages brief storage and retrieval."""

    # Schema definition for Briefly briefs
    SCHEMA = pa.schema([
        pa.field("id", pa.string()),
        pa.field("date", pa.date32()),
        pa.field("source", pa.string()),
        pa.field("content", pa.string()),
        pa.field("embedding", pa.list_(pa.float32(), 384)),  # SentenceTransformer default dim
        pa.field("voice_audio", pa.string()),
        pa.field("summary", pa.string()),
        pa.field("tags", pa.list_(pa.string())),
        pa.field("priority", pa.int32()),
        pa.field("created_at", pa.timestamp("ms")),
    ])

    def __init__(self, db_path: str = "./briefly_db", embedding_model: str = "all-MiniLM-L6-v2"):
        """
        Initialize LanceDB connection.

        Args:
            db_path: Path to local LanceDB database
            embedding_model: SentenceTransformer model name for embeddings
        """
        self.db_path = db_path
        self.embedding_model = SentenceTransformer(embedding_model)
        self.embedding_dim = 384  # Default for all-MiniLM-L6-v2

        # Connect to LanceDB (creates if doesn't exist)
        self.db = lancedb.connect(db_path)

        # Get or create briefs table
        self.table = self._get_or_create_table()

        # Multi-base: support for additional databases
        self.additional_bases: Dict[str, lancedb.DBConnection] = {}

    def _get_or_create_table(self):
        """Get existing table or create new one with schema."""
        if "briefs" not in self.db.table_names():
            print(f"Creating 'briefs' table at {self.db_path}")
            return self.db.create_table("briefs", schema=self.SCHEMAB)
        else:
            print(f"Opening existing 'briefs' table")
            return self.db.open_table("briefs")

    def add_base(self, name: str, path: str):
        """
        Add an additional LanceDB base (multi-base support).

        This allows briefs to span multiple storage locations,
        useful for:
        - Archiving old briefs to external storage
        - Distributing briefs across locations
        - Separating by time periods or categories

        Args:
            name: Name for this base
            path: Path to the additional LanceDB database
        """
        if name in self.additional_bases:
            print(f"Base '{name}' already exists")
            return

        print(f"Adding base '{name}' at {path}")
        self.additional_bases[name] = lancedb.connect(path)

        # Create briefs table in the new base if it doesn't exist
        if "briefs" not in self.additional_bases[name].table_names():
            self.additional_bases[name].create_table("briefs", schema=self.SCHEMAB)

    def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding for text content."""
        embedding = self.embedding_model.encode(text)
        return embedding.astype(np.float32).tolist()

    def insert_brief(
        self,
        brief_id: str,
        brief_date: date,
        source: str,
        content: str,
        summary: Optional[str] = None,
        voice_audio: Optional[str] = None,
        tags: Optional[List[str]] = None,
        priority: int = 5,
        base: Optional[str] = None,
    ) -> str:
        """
        Insert a brief into the database.

        Args:
            brief_id: Unique identifier
            brief_date: Date of the brief
            source: Source system (iMessage, WhatsApp, Gmail, etc.)
            content: Full content
            summary: Optional summary
            voice_audio: Optional path to audio file
            tags: Optional tags for categorization
            priority: Priority level (1-10, higher = more important)
            base: Optional base name for multi-base storage

        Returns:
            The brief_id
        """
        # Generate embedding for semantic search
        embedding = self.generate_embedding(content)

        # Use summary if provided, otherwise first 100 chars of content
        brief_summary = summary or content[:100] + "..." if len(content) > 100 else content

        brief_data = {
            "id": brief_id,
            "date": brief_date,
            "source": source,
            "content": content,
            "embedding": embedding,
            "voice_audio": voice_audio or "",
            "summary": brief_summary,
            "tags": tags or [],
            "priority": priority,
            "created_at": datetime.now(),
        }

        # Insert into specified base or default
        target_db = self.additional_bases[base] if base else self.db
        target_table = target_db.open_table("briefs")

        target_table.add([brief_data])

        base_info = f"base '{base}'" if base else "default base"
        print(f"✓ Inserted brief '{brief_id}' into {base_info}")
        return brief_id

    def semantic_search(
        self,
        query: str,
        limit: int = 5,
        source_filter: Optional[str] = None,
        date_filter: Optional[date] = None,
        min_priority: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Semantic search for briefs.

        Args:
            query: Search query (natural language)
            limit: Maximum results
            source_filter: Optional source to filter by
            date_filter: Optional date to filter by
            min_priority: Optional minimum priority level

        Returns:
            List of matching briefs with similarity scores
        """
        # Generate embedding for query
        query_embedding = self.generate_embedding(query)

        # Build where clause for filters
        where_clauses = []
        if source_filter:
            where_clauses.append(f"source = '{source_filter}'")
        if date_filter:
            where_clauses.append(f"date = '{date_filter}'")
        if min_priority:
            where_clauses.append(f"priority >= {min_priority}")

        where_clause = " AND ".join(where_clauses) if where_clauses else None

        # Search using vector similarity
        results = self.table.search(query_embedding).limit(limit).where(where_clause).to_pandas()

        print(f"\n🔍 Semantic search for: '{query}'")
        if where_clause:
            print(f"   Filters: {where_clause}")
        print(f"   Found {len(results)} results:\n")

        # Format results
        formatted_results = []
        for idx, row in results.iterrows():
            formatted_results.append({
                "id": row["id"],
                "date": str(row["date"]),
                "source": row["source"],
                "content": row["content"][:100] + "..." if len(row["content"]) > 100 else row["content"],
                "summary": row["summary"],
                "tags": row["tags"],
                "priority": row["priority"],
                "voice_audio": row["voice_audio"],
                "similarity": row.get("_score", 0.0),
            })

            print(f"  [{idx+1}] {row['source']} | Priority: {row['priority']} | Score: {row.get('_score', 0.0):.4f}")
            print(f"      {row['summary']}")
            if row["tags"]:
                print(f"      Tags: {', '.join(row['tags'])}")
            print()

        return formatted_results

    def search_by_source(self, source: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Retrieve briefs by source."""
        results = self.table.search().where(f"source = '{source}'").limit(limit).to_pandas()

        print(f"\n📂 Briefs from {source}:")
        for idx, row in results.iterrows():
            print(f"  [{idx+1}] {row['date']} | {row['summary']}")

        return results.to_dict("records")

    def search_by_date_range(
        self, start_date: date, end_date: date, limit: int = 20
    ) -> List[Dict[str, Any]]:
        """Retrieve briefs within a date range."""
        where_clause = f"date >= '{start_date}' AND date <= '{end_date}'"
        results = self.table.search().where(where_clause).limit(limit).to_pandas()

        print(f"\n📅 Briefs from {start_date} to {end_date}:")
        for idx, row in results.iterrows():
            print(f"  [{idx+1}] {row['source']} | {row['date']} | {row['summary']}")

        return results.to_dict("records")

    def search_by_tags(self, tags: List[str], limit: int = 10) -> List[Dict[str, Any]]:
        """Retrieve briefs matching any of the specified tags."""
        # Note: LanceDB doesn't have array contains, so we filter in Python
        results = self.table.search().limit(1000).to_pandas()

        # Filter by tags
        filtered = results[results["tags"].apply(lambda t: any(tag in t for tag in tags))]

        print(f"\n🏷️  Briefs with tags {tags}:")
        for idx, (_, row) in enumerate(filtered.head(limit).iterrows()):
            print(f"  [{idx+1}] {row['source']} | {row['date']} | {row['summary']}")
            print(f"      Tags: {', '.join(row['tags'])}")

        return filtered.head(limit).to_dict("records")

    def get_briefs_by_base(self, base: str, limit: int = 20) -> List[Dict[str, Any]]:
        """
        Retrieve briefs from a specific base (multi-base demonstration).

        Args:
            base: Name of the base to query
            limit: Maximum results

        Returns:
            List of briefs from the specified base
        """
        if base not in self.additional_bases:
            raise ValueError(f"Base '{base}' not found")

        base_table = self.additional_bases[base].open_table("briefs")
        results = base_table.search().limit(limit).to_pandas()

        print(f"\n🗂️  Briefs from base '{base}':")
        for idx, row in results.iterrows():
            print(f"  [{idx+1}] {row['source']} | {row['date']} | {row['summary']}")

        return results.to_dict("records")

    def get_stats(self) -> Dict[str, Any]:
        """Get statistics about briefs in the database."""
        briefs = self.table.search().limit(10000).to_pandas()

        total = len(briefs)
        sources = briefs["source"].value_counts().to_dict()
        avg_priority = briefs["priority"].mean()
        high_priority = len(briefs[briefs["priority"] >= 8])

        stats = {
            "total_briefs": total,
            "by_source": sources,
            "avg_priority": avg_priority,
            "high_priority_count": high_priority,
            "bases": list(self.additional_bases.keys()) + ["default"],
        }

        print("\n📊 Database Statistics:")
        print(f"  Total briefs: {total}")
        print(f"  Average priority: {avg_priority:.2f}")
        print(f"  High priority briefs (>=8): {high_priority}")
        print(f"  Sources:")
        for source, count in sources.items():
            print(f"    - {source}: {count}")
        print(f"  Bases: {', '.join(stats['bases'])}")

        return stats


def load_sample_data(db: BrieflyLanceDB):
    """Load sample brief data from multiple sources."""
    today = date.today()
    yesterday = today - timedelta(days=1)

    sample_briefs = [
        # iMessage briefs
        {
            "id": "imsg_001",
            "date": today,
            "source": "iMessage",
            "content": "Mom asked about dinner plans for Sunday. I need to confirm with Sarah if she's free and make a reservation at that new Italian place downtown.",
            "summary": "Dinner plans for Sunday with Mom",
            "tags": ["family", "plans", "dinner"],
            "priority": 7,
        },
        {
            "id": "imsg_002",
            "date": yesterday,
            "source": "iMessage",
            "content": "Alex sent the project proposal draft for review. Need to go through it and provide feedback by Friday EOD.",
            "summary": "Project proposal review needed",
            "tags": ["work", "project", "review"],
            "priority": 8,
        },

        # WhatsApp briefs
        {
            "id": "wa_001",
            "date": today,
            "source": "WhatsApp",
            "content": "DevOps team meeting moved from 3 PM to 4 PM today due to server maintenance scheduled for this afternoon.",
            "summary": "DevOps meeting rescheduled to 4 PM",
            "tags": ["work", "meeting", "devops"],
            "priority": 6,
        },
        {
            "id": "wa_002",
            "date": today,
            "source": "WhatsApp",
            "content": "Book club discussion is tonight at 7 PM at Lisa's place. We're discussing 'Atomic Habits'. Bring your notes!",
            "summary": "Book club tonight at Lisa's",
            "tags": ["social", "books", "club"],
            "priority": 5,
        },

        # Gmail briefs
        {
            "id": "gmail_001",
            "date": today,
            "source": "Gmail",
            "content": "Urgent: Security team detected unusual login activity on your GitHub account. Please verify your identity and update your password immediately.",
            "summary": "Security alert - GitHub login activity",
            "tags": ["security", "urgent", "github"],
            "priority": 10,
        },
        {
            "id": "gmail_002",
            "date": yesterday,
            "source": "Gmail",
            "content": "Your credit card payment of $245.50 was processed successfully. Statement closing date is January 25th.",
            "summary": "Credit card payment processed",
            "tags": ["finance", "payment"],
            "priority": 4,
        },

        # Calendar briefs
        {
            "id": "cal_001",
            "date": today,
            "source": "Calendar",
            "content": "Quarterly review meeting with stakeholders at 10 AM today. Prepare slides on Q4 performance metrics and 2024 roadmap.",
            "summary": "Quarterly review meeting at 10 AM",
            "tags": ["work", "meeting", "quarterly"],
            "priority": 9,
        },
        {
            "id": "cal_002",
            "date": today,
            "source": "Calendar",
            "content": "Dentist appointment at 2:30 PM. Remember to bring insurance card and arrive 10 minutes early.",
            "summary": "Dentist appointment at 2:30 PM",
            "tags": ["health", "appointment"],
            "priority": 6,
        },

        # Whoop briefs
        {
            "id": "whoop_001",
            "date": today,
            "source": "Whoop",
            "content": "Great recovery day! Your recovery score is 88% after 8 hours of sleep. Strain was moderate yesterday. Consider a lighter workout today.",
            "summary": "Recovery score 88%, consider light workout",
            "tags": ["health", "fitness", "recovery"],
            "priority": 5,
        },
        {
            "id": "whoop_002",
            "date": yesterday,
            "source": "Whoop",
            "content": "HRV dropped 15% compared to your baseline. This could indicate stress or fatigue. Prioritize sleep and hydration today.",
            "summary": "HRV down 15%, prioritize rest",
            "tags": ["health", "metrics", "hrv"],
            "priority": 7,
        },

        # GitHub briefs
        {
            "id": "gh_001",
            "date": today,
            "source": "GitHub",
            "content": "PR #123 'Add user authentication' is ready for review. 2 files changed, 150 additions. Please review and merge if approved.",
            "summary": "PR #123 ready for review",
            "tags": ["work", "github", "pr"],
            "priority": 8,
        },
        {
            "id": "gh_002",
            "date": yesterday,
            "source": "GitHub",
            "content": "New issue opened: 'Memory leak in data processing pipeline'. Assigned to you. High priority, affecting production.",
            "summary": "New issue: Memory leak in pipeline",
            "tags": ["bug", "high-priority", "production"],
            "priority": 10,
        },

        # LinkedIn briefs
        {
            "id": "li_001",
            "date": today,
            "source": "LinkedIn",
            "content": "You have 5 new connection requests including from senior engineers at major tech companies. Consider accepting and following up.",
            "summary": "5 new connection requests on LinkedIn",
            "tags": ["networking", "career"],
            "priority": 6,
        },
        {
            "id": "li_002",
            "date": yesterday,
            "source": "LinkedIn",
            "content": "Sarah Jenkins commented on your post about AI development. She's interested in collaboration opportunities.",
            "summary": "Sarah commented on AI post, interested in collab",
            "tags": ["networking", "opportunity"],
            "priority": 7,
        },
    ]

    print("\n📥 Loading sample brief data...")
    for brief in sample_briefs:
        db.insert_brief(**brief)

    print(f"✓ Loaded {len(sample_briefs)} sample briefs")


def demo_multi_base(db: BrieflyLanceDB):
    """Demonstrate multi-base functionality."""
    print("\n" + "="*60)
    print("🗂️  MULTI-BASE DEMONSTRATION")
    print("="*60)

    # Add a base for archived briefs
    archive_path = os.path.join(db.db_path, "archive_base")
    db.add_base("archive", archive_path)

    # Add some "archived" briefs to the archive base
    last_week = date.today() - timedelta(days=7)
    two_weeks_ago = date.today() - timedelta(days=14)

    archived_briefs = [
        {
            "id": "arch_001",
            "date": two_weeks_ago,
            "source": "Gmail",
            "content": "Annual performance review scheduled for December. Start preparing your self-assessment and gather feedback from colleagues.",
            "summary": "Annual review prep reminder",
            "tags": ["work", "review"],
            "priority": 7,
            "base": "archive",
        },
        {
            "id": "arch_002",
            "date": last_week,
            "source": "Calendar",
            "content": "Team offsite event confirmed for next month. Hotel bookings complete, agenda finalized with HR.",
            "summary": "Team offsite confirmed for next month",
            "tags": ["work", "event", "team"],
            "priority": 6,
            "base": "archive",
        },
        {
            "id": "arch_003",
            "date": two_weeks_ago,
            "source": "Whoop",
            "content": "New personal best on 5K run! Completed in 22:30. Recovery metrics suggest you're ready for increased training intensity.",
            "summary": "Personal best on 5K run",
            "tags": ["fitness", "achievement", "pr"],
            "priority": 5,
            "base": "archive",
        },
    ]

    print("\n📥 Loading archived briefs to 'archive' base...")
    for brief in archived_briefs:
        db.insert_brief(**brief)

    # Retrieve briefs from archive base
    db.get_briefs_by_base("archive")


def demo_semantic_search(db: BrieflyLanceDB):
    """Demonstrate semantic search capabilities."""
    print("\n" + "="*60)
    print("🔍 SEMANTIC SEARCH DEMONSTRATION")
    print("="*60)

    # Example 1: Search by topic across all sources
    db.semantic_search("work meetings and deadlines")

    # Example 2: Search for health-related content
    db.semantic_search("health and fitness metrics")

    # Example 3: Search for security issues
    db.semantic_search("security alerts and urgent issues")

    # Example 4: Search with source filter
    db.semantic_search("project updates", source_filter="iMessage")

    # Example 5: Search with priority filter
    db.semantic_search("important tasks", min_priority=8)


def demo_source_filtering(db: BrieflyLanceDB):
    """Demonstrate source-based filtering."""
    print("\n" + "="*60)
    print("📂 SOURCE-BASED FILTERING")
    print("="*60)

    db.search_by_source("iMessage")
    db.search_by_source("Whoop")


def demo_tag_filtering(db: BrieflyLanceDB):
    """Demonstrate tag-based filtering."""
    print("\n" + "="*60)
    print("🏷️  TAG-BASED FILTERING")
    print("="*60)

    db.search_by_tags(["work", "review"])
    db.search_by_tags(["health"])


def demo_date_filtering(db: BrieflyLanceDB):
    """Demonstrate date-based filtering."""
    print("\n" + "="*60)
    print("📅 DATE-BASED FILTERING")
    print("="*60)

    today = date.today()
    yesterday = today - timedelta(days=1)
    db.search_by_date_range(yesterday, today)


def main():
    """Main demonstration function."""
    print("="*60)
    print("Briefly LanceDB POC")
    print("Demonstrating LanceDB for Brief Synthesis and Retrieval")
    print("="*60)

    # Initialize database
    db = BrieflyLanceDB(db_path="./briefly_db")

    # Load sample data from multiple sources
    load_sample_data(db)

    # Get statistics
    db.get_stats()

    # Demonstrate semantic search
    demo_semantic_search(db)

    # Demonstrate source-based filtering
    demo_source_filtering(db)

    # Demonstrate tag-based filtering
    demo_tag_filtering(db)

    # Demonstrate date-based filtering
    demo_date_filtering(db)

    # Demonstrate multi-base functionality
    demo_multi_base(db)

    print("\n" + "="*60)
    print("✅ POC Complete!")
    print("="*60)
    print("\nKey Benefits Demonstrated:")
    print("  ✓ Multi-source aggregation in one table")
    print("  ✓ Semantic search across briefs")
    print("  ✓ Multi-base for distributed brief storage")
    print("  ✓ Flexible filtering by source, tags, date, priority")
    print("\nDatabase location: ./briefly_db")


if __name__ == "__main__":
    main()
