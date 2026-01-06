# Briefly Redesign Phase 3: Synthesis & Integration

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate the new Providers into `BriefService`, implement the `BraveSearchProvider` for meeting research, and add the LLM synthesis layer.

**Architecture:** We will update `BriefService` to use a list of `Provider` objects, add a `ResearchService` that triggers on specific entities, and implement a `SynthesisService` that calls an LLM.

**Tech Stack:** Swift 6.2, Brave Search API, OpenAI/Anthropic API (via environment variables).

---

### Task 8: ResearchService & Entity Cache

**Files:**
- Create: `Sources/brieflyCLI/Services/ResearchService.swift`
- Create: `Sources/brieflyCLI/Utility/EntityCache.swift`

**Step 1: Implement EntityCache**
A simple JSON cache in `~/.briefly/entity_cache.json` to store research results.

**Step 2: Implement ResearchService**
Uses `BraveSearchProvider` (to be created) to lookup names/companies and store results in cache.

---

### Task 9: BraveSearchProvider

**Files:**
- Create: `Sources/brieflyCLI/Services/BraveSearchProvider.swift`

**Step 1: Implementation**
Use `curl` or a native networking call to hit the Brave Search API. Requires `BRAVE_SEARCH_API_KEY`.

---

### Task 10: SynthesisService (LLM)

**Files:**
- Create: `Sources/brieflyCLI/Services/SynthesisService.swift`

**Step 1: Implementation**
A service that takes the aggregated provider data + research results and sends it to an LLM for final summary generation.

---

### Task 11: Refactor BriefService

**Files:**
- Modify: `Sources/brieflyCLI/Services/BriefService.swift`

**Step 1: Integration**
Update `generateBrief` to:
1. Initialize providers.
2. Check statuses.
3. Fetch data in parallel.
4. Trigger research on discovered entities.
5. Call `SynthesisService` for the final result.

---

### Task 12: Update SetupCommand

**Files:**
- Modify: `Sources/brieflyCLI/Commands/SetupCommand.swift`

**Step 1: Implementation**
Update the command to actually attempt `DependencyManager.verifyPresence()` and provide installation instructions for missing tools.
