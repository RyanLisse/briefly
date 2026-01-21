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
