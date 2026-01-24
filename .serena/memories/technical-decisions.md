Key technical decisions for briefly voice engine implementation:

1. VoiceEngine Protocol: Chosen for pluggability and testability. Allows easy switching between local/cloud engines without changing core logic. Enables dependency injection in BriefService.

2. MLX as Default Engine: Provides privacy (no data sent to cloud), cost benefits (no API calls), and offline capability. GabGab integration ensures local MLX models (Kokoro-82M/LFM 2.5) work efficiently.

3. ElevenLabs Fallback: Maintains backward compatibility and provides enhanced voice options when local models are insufficient. Used as fallback when MLX fails.

4. Dependency Injection in BriefService: Allows engine selection at runtime, enables testing with mocks, and keeps business logic separate from infrastructure concerns.

5. CLI Flags (--engine, --profile): Gives users control over voice synthesis while maintaining sensible defaults. --engine for engine selection, --profile for voice variants.

6. MCP Server Integration: Added engine selection parameters to generate_daily_brief tool, maintaining API compatibility while extending functionality.

7. GabGab Local Dependency: Integrated as SwiftPM local path dependency rather than remote package to ensure control over voice synthesis dependencies and avoid external API reliance for core functionality.

8. Swift 6 Concurrency: Extensive use of async/await and actors for thread safety and parallel data fetching, following project conventions.

9. Peekaboo Architecture: Maintained executable/library separation, with CLI commands delegating to Core services.

10. Benchmark Command: Implemented for performance validation and future optimization needs, following CLI-first approach.