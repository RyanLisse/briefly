import Foundation

public actor ShellExecutor {
    public init() {}
    
    public func execute(_ command: String, arguments: [String] = [], timeout: TimeInterval = 30.0) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await withTaskCancellationHandler {
                    try await Task.detached {
                        try process.run()
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        process.waitUntilExit()
                        return String(data: data, encoding: .utf8) ?? ""
                    }.value
                } onCancel: {
                    if process.isRunning {
                        process.terminate()
                    }
                }
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if process.isRunning {
                    process.terminate()
                }
                throw ShellError.timeout(command: command)
            }
            
            do {
                guard let result = try await group.next() else {
                    throw ShellError.unknown
                }
                group.cancelAll()
                return result
            } catch {
                if process.isRunning {
                    process.terminate()
                }
                throw error
            }
        }
    }
}

public enum ShellError: Error {
    case timeout(command: String)
    case unknown
}
