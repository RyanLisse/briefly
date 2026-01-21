# Planning Workflow: Briefly Local Voice Refactor (MLX Stack)
**Status:** Draft · **Date:** 2026-01-21 · **Methodology:** planning-workflow (Jeffrey Emanuel’s 85% planning, multi-round review, beads conversion)

## Executive Summary
`briefly` already captures the daily brief with cloud TTS (ElevenLabs) and Whisper STT, but the cost and latency profile still rely on third-party APIs. This plan refactors `briefly` into a **native Swift voice-first experience** that defaults to the local MLX stack (Kokoro + Parakeet + Smart Turn) while preserving the existing ElevenLabs pipeline as a safe fallback. The work hooks the local voice router into the Swift project, introduces a `VoiceEngine` protocol, adds CLI & MCP knobs, and documents the transition along the planning → beads workflow.

## Goals & Success Criteria
1. **Primary:** Run the daily brief generation entirely through the local MLX voice stack (Kokoro-82M via `mlx-audio` + Parakeet streaming STT when voice mode is active, with Smart Turn semantics) without rebuilding the CLI’s core logic.
2. **Fallback assurance:** Keep ElevenLabs (via `sag`) available, and allow `--engine cloud` or `VOICE_PROFILE=elevenlabs` to switch back whenever needed.
3. **Native Swift refactor:** Introduce a `VoiceEngine` abstraction that lives inside the Swift project (no external Python wrappers for core logic) and exposes configuration + benchmarking hooks.
4. **Observable metrics:** Track latency + cost delta, ensure the new default produces high-quality audio, and surface relevant logs/helm (Voice mode detection, engine selection, Smart Turn triggers).

Success Criteria:
- `briefly` command with default voice uses `MLXVoiceEngine`, and `briefly voice --engine cloud` still runs the ElevenLabs path.
- Voice mode detection (voice in → voice out) now flows through the native stack and logs Smart Turn decisions within the Swift logs.
- Benchmark command or doc captures the latency/RTF of the new engine vs the old route.

## Implementation Status
- `VoiceEngine`, `MLXVoiceEngine`, and `ElevenLabsVoiceEngine` are implemented in `Sources/Core/Voice/`.
- CLI and MCP tooling accept engine/profile overrides and default to local MLX.
- `briefly voice benchmark` writes JSON + Markdown outputs to `logs/`.

## Current State & Reference Plans
- **Existing implementation:** `~/Developer/briefly` still calls `sag` (ElevenLabs) plus Whisper via the scripts referenced in `docs/plans/MLX_VOICE_UPGRADE.md`. Automatic mode matching is documented in `voice-mode-setup.md` (voice in → voice out, text in → text out) and remains the expected UX.
- **MLX research:** `projects/local-voice-system/MLX_VOICE_PLAN.md` and `memory/voice-model-research-2026.md` provide the prioritized stack (Kokoro 82M, Parakeet 0.6b, Smart Turn v3.x, the `mlx-audio` REST glue). We mirror that stack inside `briefly` by wiring the Swift project to the same local runtime.
- **GabGab/MLXVoice:** The `MLXVoice` Swift package under `Main SSD/Developer/GabGab` already implements the same MLX-first client (`MLXVoiceSessionManager`) plus CLI/MCP tooling, fallbacks via `voice_router.py`, health checks, and `AVAudioEngine` playback. We plan to import that package as a local dependency so `MLXVoiceEngine` becomes a thin wrapper around `MLXVoiceSessionManager` instead of re-implementing multipart HTTP and fallback logic.

## User Workflows (from Briefly’s POV)
| Workflow | Description | Priority |
| --- | --- | --- |
| **Daily brief narration** | text output → local MLX TTS (Kokoro) + Smart Turn cadence when delivering audio summary | P0 |
| **Voice message response** | incoming audio (Telegram/iMessage) → Smart Turn / Parakeet → LLM → Kokoro voice response (streamed if possible) | P0 |
| **Manual benchmarking** | `briefly voice benchmark` command compares `local` vs `cloud` paths with JSON/Markdown output + log evidence | P1 |

## Tech Stack & Architecture
1. **VoiceEngine protocol (Swift):** `synthesize(text: String, urgency: VoiceUrgency, output: URL) async throws -> VoiceGeneration`. Implementation choices: `MLXVoiceEngine` (default) + `ElevenLabsVoiceEngine` (fallback).
2. **Model routing:** `MLXVoiceEngine` talks to `mlx-audio` (OpenAI-compatible server) running on localhost or via embedded `voice_router.py`. Streams in Parakeet transcriptions to Smart Turn when voice input is enabled.
3. **Smart Turn Integration:** `SmartTurnAnalyzer` (Rust-bound or Python guard) signals the voice loop inside Swift (via callbacks or `Process` output) so responses start the instant the user is finished.
4. **Configuration:** CLI + MCP commands read `VOICE_ENGINE`, `VOICE_PROFILE`, `STT_PROFILE` env vars; default to `local` plus logging to `logs/voice-engine.log`.
5. **Native Swift Module:** The voice engine lives inside `Sources/brieflyCLI/Voice/` (new module) so we keep Swift-only functionality, referencing bridging to mlx stack via `ShellExecutor` and/or `URLSession` hitting the `mlx-audio` server.
6. **Package dependency:** Add `/Volumes/Main SSD/Developer/GabGab/MLXVoice` as a local SwiftPM dependency so `MLXVoiceSessionManager` can be imported directly, and export the new `Voice` namespace through `Package.swift`.

## Planning Workflow Phases
1. **Initial plan creation (today).** Write this doc, capturing goals, workflows, and research. Use GPT Pro Extended Reasoning with the prompt from `planning-workflow` to review the plan and produce structural improvements (target 4-5 rounds). Save outputs in `docs/plans/PLAN_REVISIONS.md`.
2. **Iterative refinement.** Feed updates into Claude Code (Opus 4.5 + GPT Pro) with the “Review the entire plan and revise” prompt; ensure the native Swift refactor and fallback logic remain intact.
3. **Multi-model blend (optional).** After humans review, optionally run multi-model blending with Gemini3 Deep Think + Grok4 Heavy vs GPT Pro to surface alternative architecture ideas (e.g., streaming vs chunked TTS). Document diff-style revisions inside this plan doc.
4. **Convert to beads.** Once plan steady-state, convert to bead tasks (below) using `bd convert`. This ensures we have actionable tasks for `briefly` voice refactor. Use `bd` to capture dependencies, tests, verification steps, and doc updates.
5. **Implementation review.** After beads in place, run `bd polish` (per `beads-workflow` skill) in 6+ rounds to ensure self-contained tasks with tests/integration coverage.

## Next Steps
- Share this plan with GPT Pro (Extended Reasoning) and absorb feedback into the document (include plan diff notes in `docs/plans/PLAN_REVISIONS.md`).
- Initialize `bd` inside `projects/Developer/briefly` and create beads for the refactor (covering engine abstractions, MLX wiring, CLI flags, performance harness, docs/testing).
- Create a `briefly voice benchmark` command that hits the same harness used by the local voice stack plan to capture latency and RTF.
- Update docs (`README.md`, `docs/plans/MLX_VOICE_UPGRADE.md`, `docs/voice-mode-setup.md`) with the new plan summary and fallback instructions.
- Convert the plan to beads + run multi-agent review as needed before implementation begins.
