import XCTest
@testable import Core

final class VoiceEngineFactoryTests: XCTestCase {
    func testResolveConfigKeepsCloud() async {
        let config = VoiceConfig.fromEnvironment().withOverrides(
            engine: .cloud,
            profile: nil,
            sttProfile: nil,
            voiceMode: nil
        )
        let resolved = await VoiceEngineFactory.resolveConfig(config: config)
        XCTAssertEqual(resolved.engine, .cloud)
    }
}
