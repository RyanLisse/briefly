# Plan: MLX-Optimized Voice Upgrade for Briefly

**Status:** Implemented · **Date:** 2026-01-21
**Target:** `/Volumes/Main SSD/Developer/briefly`

## 1. Objective
Refactor the `briefly` voice generation system to use local MLX-optimized models (**Kokoro-82M** and **LFM 2.5 Audio**) by default, significantly reducing latency and API costs while maintaining high quality.

## 2. Technical Strategy

### 2.1 Multi-Engine Architecture
Transition from a hardcoded ElevenLabs dependency to a modular engine pattern.

- **Protocol:** `VoiceEngine`
  - `func synthesize(text: String, profile: VoiceProfile, outputURL: URL) async throws -> VoiceGeneration`
- **Implementation A:** `ElevenLabsVoiceEngine` (Legacy/Cloud fallback)
- **Implementation B:** `MLXVoiceEngine` (Default/Local)
  - Talks to the `mlx-audio` OpenAI-compatible REST server.

### 2.2 Integration Details
- **Location:** `Sources/Core/Services/BriefService.swift`
- **Logic:**
  - Initialize `BriefService` with a default engine based on user preference or environment variables.
  - Implement a `Soft Cascade`: Try `local` -> Fallback to `cloud` (ElevenLabs) on failure or when requested.

### 2.3 CLI Enhancements
- **Location:** `Sources/CLI/Commands/BriefCommand.swift`
- **New Flags:**
  - `--voice`: Enables voice output (defaults to local MLX engine).
  - `--engine [local|cloud]`: Explicitly select the synthesis engine.
  - `--voice-profile [normal|premium]`: Select model (Kokoro for normal, LFM 2.5 for premium).
  - `--stt-profile [parakeet|whisper]`: Configure STT profile.
  - `--voice-mode [auto|always|never]`: Control voice output behavior.

## 3. Implementation Steps

### Phase 1: Engine Refactoring
1. Define the `VoiceEngine` protocol in `Sources/Core/Voice/`.
2. Extract the existing ElevenLabs logic into `ElevenLabsVoiceEngine.swift`.
3. Create `MLXVoiceEngine.swift` that uses the MLX REST server.

### Phase 2: Configuration & Defaults
1. Add `VoiceConfig` with env/CLI overrides.
2. Set `MLXVoiceEngine` as the default when `--voice` is used.
3. Add configuration keys to setup for local model paths and profiles.

### Phase 3: Optimization
1. **REST Integration:** Update `MLXVoiceEngine` to use `URLSession` to talk to a persistent `mlx-audio` server (port 8080) instead of spawning processes.
2. **Streaming Support:** (Optional) Explore streaming audio chunks to the player if `briefly` supports playback during generation.

### Phase 4: Verification
1. Add unit tests for config parsing and engine selection.
2. Benchmark `local` vs `cloud` latency using `briefly voice benchmark`.
3. Validate audio quality of the generated Daily Brief.

## 4. Next Steps
1. Run `briefly voice benchmark` on local MLX and capture baseline metrics.
2. Integrate Smart Turn stream events with the MLX server for lower latency.
3. Expand tests for Smart Turn and CLI validation.
