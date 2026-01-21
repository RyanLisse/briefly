import XCTest
@testable import Core

final class VoiceConfigTests: XCTestCase {
    func testVoiceConfigDefaults() {
        let config = VoiceConfig.fromEnvironment()
        XCTAssertEqual(config.engine, .local)
        XCTAssertEqual(config.profile, .normal)
        XCTAssertEqual(config.sttProfile, .parakeet)
        XCTAssertEqual(config.voiceMode, .auto)
    }

    func testVoiceConfigOverrides() {
        setenv("VOICE_ENGINE", "cloud", 1)
        setenv("VOICE_PROFILE", "premium", 1)
        setenv("STT_PROFILE", "whisper", 1)
        setenv("VOICE_MODE", "always", 1)
        defer {
            unsetenv("VOICE_ENGINE")
            unsetenv("VOICE_PROFILE")
            unsetenv("STT_PROFILE")
            unsetenv("VOICE_MODE")
        }

        let config = VoiceConfig.fromEnvironment()
        XCTAssertEqual(config.engine, .cloud)
        XCTAssertEqual(config.profile, .premium)
        XCTAssertEqual(config.sttProfile, .whisper)
        XCTAssertEqual(config.voiceMode, .always)
    }
}
