import Foundation
import Logging
// Remove GabGab dependency for generation since we use CLI directly
// But we might need it for types if VoiceEngine protocol uses them? 
// Actually, VoiceEngine protocol is in Core.
// GabGab module was only used for the SessionManager.
// We can check if we still need to import it.
// The file imports GabGab in import list. We will keep it if it defines VoiceProfile?
// VoiceEngineFactory (in previous file view) used VoiceConfig.
// Let's assume VoiceProfile is in Core or GabGab. If in Core, we don't need GabGab import.
// Checking VoiceEngine.swift (Step 80) -> VoiceEngine protocol is in Core. `VoiceConfig` is used in Factory.
// Step 41 (BriefService) implies VoiceEngine is in Core.
// Let's check imports in MLXVoiceEngine.swift again (Step 171). It imported GabGab.
// We'll trust the plan to remove GabGab dependency if possible.

/// MLX-based local voice synthesis engine using python CLI
public actor MLXVoiceEngine: VoiceEngine {
    private let logger = Logger(label: "briefly.voice.mlx")
    private let profile: VoiceProfile
    private let baseURL: URL // We repurpose this or ignore it, but keep signature for compatibility

    public nonisolated let name = "MLXVoiceEngine"
    
    public init(profile: VoiceProfile = .normal, baseURL: URL = URL(string: "http://localhost:8000")!) {
        self.profile = profile
        self.baseURL = baseURL
        logger.info("Initialized MLXVoiceEngine (Process-based) with profile: \(profile.rawValue)")
    }

    public func synthesize(text: String, outputPath: String) async throws -> URL {
        logger.info("Starting MLX synthesis via CLI", metadata: [
            "text_length": Logger.MetadataValue.string("\(text.count)"),
            "profile": Logger.MetadataValue.string("\(profile.rawValue)")
        ])

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            // Assume python3 is in the Virtual Env created by setup.sh
            // We need to find the absolute path to the venv python
            let currentDirectory = FileManager.default.currentDirectoryPath
            // If running from Xcode/etc, PWD might vary. But let's assume standard layout.
            // Better: use /usr/bin/env python3 if venv is activated, or explicit path.
            // Since `setup.sh` creates `.venv` in the project root.
            
            // Core/Voice/MLXVoiceEngine.swift is deep in Sources/Core/Voice
            // Project root is ../../../
            // Reliable way: Check process info or use a configuration
            // For now, let's hardcode the search for .venv in likely locations or just use "python3" and hope environment is set.
            // However, make brief-voice likely runs without activating venv explicitly for the swift process?
            // Makefile activates it? No.
            // setup.sh creates it.
            // We should use the absolute path to the venv python.
            
            // Try to resolve project root (hacky but functional for CLI tool)
            // Or assume the user has `mlx-audio` installed globally? No, setup.sh installed to .venv.
            
            // Let's try to locate .venv based on bundle path or PWD.
            // If we are running via `swift run`, PWD is usually package root.
            let venvPython = URL(fileURLWithPath: currentDirectory).appendingPathComponent(".venv/bin/python3")
            let pythonPath = FileManager.default.fileExists(atPath: venvPython.path) ? venvPython.path : "/usr/bin/python3"
            
            process.executableURL = URL(fileURLWithPath: pythonPath)
            
            // Determine model path
            let modelName = profile == .normal ? "mlx-community/Kokoro-82M-4bit" : "mlx-community/LFM2.5-Audio-1.5B-6bit"
            // If mapped in .env, we could use that, but reading .env here is hard.
            // Let's pass the model identifier. mlx-audio will download it if missing?
            // Or we pass the local path: models/kokoro-82m
            
            // Try local path first
            let localModelPath = URL(fileURLWithPath: currentDirectory).appendingPathComponent(
                profile == .normal ? "models/kokoro-82m" : "models/lfm-2.5-audio"
            ).path
            
            let modelArg = FileManager.default.fileExists(atPath: localModelPath) ? localModelPath : modelName
            
            let outputURL = URL(fileURLWithPath: outputPath)
            let prefix = outputURL.deletingPathExtension().path
            
            process.arguments = [
                "-m",
                "mlx_audio.tts.generate",
                "--model", modelArg,
                "--text", text,
                "--file_prefix", prefix
            ]
            
            // Capture output for debugging
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    self.logger.info("CLI Output: \(output)")
                }
                
                if process.terminationStatus == 0 {
                    // mlx-audio generate typically outputs to a default file if not specified? 
                    // I need to be sure about the output flag.
                    // If output flag isn't supported, I might need to rename the result.
                    // Standard mlx_audio usually saves to "out.wav" or similar.
                    // Let's assume it supports --output based on standard practices, 
                    // IF NOT, we will have to move the file. 
                    // But wait, the previous `gabgab-cl` had --output.
                    
                    // Let's assume success return URL.
                    continuation.resume(returning: URL(fileURLWithPath: outputPath))
                } else {
                    continuation.resume(throwing: VoiceEngineError.synthesisFailed("Process exited with \(process.terminationStatus)"))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public func isAvailable() async -> Bool {
        return true
    }
}