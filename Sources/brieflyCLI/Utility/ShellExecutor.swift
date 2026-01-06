import Foundation

public actor ShellExecutor {
    public init() {}
    
    public func execute(_ command: String, arguments: [String] = []) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        
        let data = try pipe.fileHandleForReading.readToEnd()
        process.waitUntilExit()
        
        return String(data: data ?? Data(), encoding: .utf8) ?? ""
    }
}
