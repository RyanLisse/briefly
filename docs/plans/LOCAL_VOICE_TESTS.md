# Local Voice Tests

## Unit tests

- `VoiceConfig` parsing from environment defaults.
- CLI overrides for `--engine`, `--voice-profile`, `--stt-profile`, `--voice-mode`.
- Engine fallback when MLX health check fails.

## Integration tests

- `briefly brief --voice --engine local` produces an audio file via MLX server.
- `briefly brief --voice --engine cloud` uses ElevenLabs fallback when API key is set.
- `briefly voice benchmark` writes JSON + Markdown outputs to `logs/`.

## Manual checks

- Confirm `logs/voice-engine.log` records engine selection and latency.
- Confirm `logs/smart_turn.log` records Smart Turn status and fallback.
