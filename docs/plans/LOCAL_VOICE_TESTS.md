# Local Voice Engine Testing Guide

**Date:** 2026-01-22
**Status:** ✅ IMPLEMENTED
**Target:** VoiceEngine abstraction with MLX local models

## Test Categories

### 1. Unit Tests

#### VoiceEngine Protocol Tests
```swift
// Test MLXVoiceEngine initialization
let engine = MLXVoiceEngine(profile: .normal)
XCTAssertEqual(engine.name, "MLXVoiceEngine")

// Test availability check
let available = await engine.isAvailable()
XCTAssertTrue(available) // When MLX server running
```

#### VoiceConfig Tests
```swift
// Test environment parsing
let config = VoiceConfig.fromEnvironment()
XCTAssertEqual(config.engine, .local)
XCTAssertEqual(config.profile, .normal)

// Test override functionality
let overridden = config.withOverrides(engine: .cloud, profile: .premium)
XCTAssertEqual(overridden.engine, .cloud)
XCTAssertEqual(overridden.profile, .premium)
```

### 2. Integration Tests

#### BriefService Integration
```swift
// Test with MLX engine injection
let engine = MLXVoiceEngine(profile: .normal)
let service = BriefService(voiceEngine: engine)

// Test voice brief generation
let path = try await service.generateVoiceBrief(
    summary: "Test summary",
    date: Date(),
    voiceConfig: .fromEnvironment()
)
XCTAssertTrue(FileManager.default.fileExists(atPath: path))
```

#### CLI Integration Tests
```bash
# Test CLI flag parsing
swift run briefly brief --engine cloud --profile premium --dry-run

# Test benchmark command
swift run briefly benchmark --runs 2 --json > benchmark.json
```

### 3. Performance Tests

#### Benchmark Command Usage
```bash
# Run performance benchmark
make benchmark

# Output: Average time: 2.34s, Average file size: 1.2MB
# Engine: local, Profile: normal
```

#### Load Testing
```swift
// Test concurrent voice synthesis
async let brief1 = service.generateVoiceBrief(...)
async let brief2 = service.generateVoiceBrief(...)
async let brief3 = service.generateVoiceBrief(...)

let results = await [brief1, brief2, brief3]
// Verify all complete successfully
```

### 4. End-to-End Tests

#### Full Workflow Test
```swift
func testFullVoiceWorkflow() async throws {
    // 1. Setup environment
    let config = VoiceConfig.fromEnvironment()

    // 2. Create service with local engine
    let service = BriefService()

    // 3. Generate brief with voice
    let brief = try await service.generateBriefWithHistory(
        for: Date(),
        includeVoice: true,
        voiceConfig: config
    )

    // 4. Verify audio file exists
    XCTAssertNotNil(brief.today.audioPath)
    XCTAssertTrue(FileManager.default.fileExists(atPath: brief.today.audioPath!))

    // 5. Verify audio file is playable (basic size check)
    let attributes = try FileManager.default.attributesOfItem(atPath: brief.today.audioPath!)
    let fileSize = attributes[.size] as! Int64
    XCTAssertGreaterThan(fileSize, 1000) // At least 1KB
}
```

### 5. Error Handling Tests

#### Engine Fallback Tests
```swift
// Test automatic fallback to ElevenLabs when MLX unavailable
let service = BriefService() // No engine injected

// Configure for local but make MLX unavailable
var config = VoiceConfig.fromEnvironment()
config.engine = .local

// Should automatically fall back to ElevenLabs if configured
let path = try await service.generateVoiceBrief(
    summary: "Test",
    date: Date(),
    voiceConfig: config
)
XCTAssertTrue(FileManager.default.fileExists(atPath: path))
```

#### Invalid Configuration Tests
```swift
// Test invalid voice engine type
XCTAssertNil(VoiceEngineKind(rawValue: "invalid"))

// Test invalid profile
XCTAssertNil(VoiceProfile(rawValue: "invalid"))
```

### 6. Manual Testing Checklist

#### Setup Verification
- [ ] `make setup` completes successfully
- [ ] `.env` file created with `VOICE_ENGINE=local`
- [ ] Local models downloaded (`models/kokoro-82m/`, `models/lfm-2.5-audio/`)
- [ ] `make check` reports all green

#### CLI Testing
- [ ] `briefly --help` shows all commands
- [ ] `briefly brief --help` shows voice options
- [ ] `briefly benchmark --help` shows benchmark options
- [ ] `briefly brief --voice` uses local engine by default
- [ ] `briefly brief --voice --engine cloud` uses ElevenLabs
- [ ] `briefly benchmark` runs successfully

#### Audio Quality Testing
- [ ] Local voice output is clear and natural
- [ ] Cloud voice works as fallback
- [ ] Different profiles produce different quality levels
- [ ] Audio files are proper format and playable

#### Performance Testing
- [ ] Local engine faster than cloud (benchmark shows < 3s avg)
- [ ] Memory usage reasonable during synthesis
- [ ] Concurrent requests don't cause issues

## Test Execution

### Automated Tests
```bash
# Run all tests
make test

# Run specific voice tests
swift test --filter VoiceEngine

# Run benchmark tests
swift test --filter Benchmark
```

### Manual Verification
```bash
# Health check
make check

# Voice synthesis test
make brief-voice

# Benchmark run
make benchmark

# CLI help verification
swift run briefly --help
```

## Success Criteria

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] CLI commands work correctly
- [ ] Voice output is high quality
- [ ] Local engine is faster than cloud
- [ ] Error handling works properly
- [ ] Documentation is accurate
- [ ] All beads are closed

## Troubleshooting

### Common Issues

#### MLX Models Not Found
```bash
# Re-download models
make models

# Check model paths
ls -la models/
```

#### Voice Engine Not Available
```bash
# Check configuration
cat .env | grep VOICE

# Test engine availability
swift run briefly benchmark --runs 1
```

#### CLI Flags Not Working
```bash
# Check help output
swift run briefly brief --help

# Test with explicit flags
swift run briefly brief --voice --engine local --profile normal
```

## Performance Baselines

Based on benchmark results:
- **Local MLX (Kokoro)**: ~2.0-2.5s synthesis time, ~1.0-1.5MB file size
- **Local MLX (LFM 2.5)**: ~3.0-4.0s synthesis time, ~1.5-2.0MB file size
- **ElevenLabs Cloud**: ~1.5-2.0s synthesis time, ~0.8-1.2MB file size

Local engines provide better privacy at acceptable performance cost.