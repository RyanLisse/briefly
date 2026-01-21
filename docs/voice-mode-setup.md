# Voice Mode Setup

Briefly supports multiple voice modes to match how you use the CLI.

## Modes

- `auto` (default): Voice output is generated only when you pass `--voice`.
- `always`: Voice output is generated for every brief automatically.
- `never`: Voice output is disabled (even if `--voice` is passed).

## Configure via `.env`

```bash
VOICE_MODE=auto    # auto | always | never
VOICE_ENGINE=local # local | cloud
VOICE_PROFILE=normal # normal | premium
STT_PROFILE=parakeet # parakeet | whisper
```

## CLI overrides

```bash
briefly brief --voice --engine local --voice-profile premium
```

## Fallback behavior

If you select `local` and the MLX server fails its health check, Briefly will
automatically fall back to the `cloud` engine and log the event in
`logs/voice-engine.log`.
