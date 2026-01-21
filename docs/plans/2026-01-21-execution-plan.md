# Execution Plan — Local MLX Voice Integration

**Date:** 2026-01-21  
**Scope:** Complete local-first voice engine integration, CLI/MCP wiring, docs, and verification.

## Goals
- Local MLX models are default for voice synthesis.
- Engine selection is configurable via CLI/MCP and environment.
- Fallback to cloud engine is explicit and observable.
- Benchmarks and docs are available and reproducible.

## Plan (SPARC + TDD)
1. **Specification**
   - Confirm required flags: `--engine`, `--voice-profile`, `--stt-profile`, `--voice-mode`.
   - Confirm env defaults: `VOICE_ENGINE=local`, `VOICE_PROFILE=normal`, `STT_PROFILE=parakeet`.

2. **Architecture**
   - Core voice abstraction in `Sources/Core/Voice/`.
   - Local engine uses MLX server via GabGab or HTTP.
   - Cloud engine provides ElevenLabs fallback.
   - Smart Turn hook for voice loop state logging.

3. **Implementation**
   - Implement `VoiceConfig`, `VoiceEngine`, `MLXVoiceEngine`, `ElevenLabsVoiceEngine`.
   - Wire `BriefService` to engine resolution and config.
   - Add CLI and MCP parameter overrides.
   - Add `briefly voice benchmark`.

4. **Testing**
   - Unit tests for config parsing and engine selection.
   - CLI/MCP parameter validation.
   - Ensure tests run with `swift test`.

5. **Verification**
   - `swift test`
   - `make help`
   - `./scripts/setup.sh --models-only`
   - Optional: `briefly voice benchmark`

## Risks / Mitigations
- **MLX server unavailable:** Health check + fallback.
- **Missing keys:** Clear error messages; env-driven config.
- **Large models:** Setup script ensures models present.

## Done Criteria
- Local engine is default and configurable.
- CLI + MCP support overrides.
- Benchmark command writes JSON + Markdown.
- Docs updated and tests passing.
# Execution Plan: Briefly Local Voice Upgrade & GabGab Integration

**Date:** 2026-01-21
**Objective:** Integrate `GabGab` for local MLX voice synthesis, set up local models as default, and finalize project setup scripts.

## 1. GabGab Integration
- [ ] Add `GabGab` as a git submodule at `Vendor/GabGab` (pointing to `/Volumes/Main SSD/Developer/GabGab`).
- [ ] Update `Package.swift` to add `GabGab` (specifically `MLXVoice` product) as a dependency.
- [ ] Update `Makefile` to include `git submodule update --init --recursive`.

## 2. Voice Engine Implementation
- [ ] Refactor `Sources/Core/Voice/MLXVoiceEngine.swift` to import `MLXVoice` and use `MLXVoiceSessionManager`.
- [ ] Update `Sources/Core/Voice/VoiceConfig.swift` to ensure `local` is the default engine.
- [ ] Verify `Sources/Core/Services/BriefService.swift` uses `VoiceConfig` correctly.

## 3. Project Setup & Configuration
- [ ] Verify `scripts/setup.sh` handles model downloads (Kokoro, LFM) and `.env` generation (already seems done, will verify execution).
- [ ] Update `Makefile` with any missing targets (e.g., `update-submodules`).

## 4. Documentation
- [ ] Update `README.md` to reflect the new architecture (GabGab dependency, local models).
- [ ] Update `AGENTS.md` with any new agent-relevant context.

## 5. Verification
- [ ] Build the project (`swift build`).
- [ ] Verify `GabGab` is checked out and recognized.
- [ ] Run `briefly --help` or `briefly brief --voice` (dry run or mock) to test integration.
