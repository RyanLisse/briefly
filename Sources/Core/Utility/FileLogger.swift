import Foundation

public enum FileLogger {
    public static func appendLine(_ message: String, to filename: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let logsURL = rootURL.appendingPathComponent("logs", isDirectory: true)
        let fileURL = logsURL.appendingPathComponent(filename)

        do {
            try FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let handle = try FileHandle(forWritingTo: fileURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.close()
            } else {
                try data.write(to: fileURL, options: .atomic)
            }
        } catch {
            // Best-effort logging only
        }
    }
}
