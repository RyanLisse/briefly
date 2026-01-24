import ArgumentParser
import Foundation
import Core

/// Command to export SCOBY system health reports.
///
/// This command generates and saves a comprehensive system health report
/// in markdown format, suitable for inclusion in daily briefs or standalone analysis.
///
/// Usage:
/// ```bash
/// briefly scoby-export                    # Export to default location
/// briefly scoby-export --output ./report.md  # Export to specific file
/// briefly scoby-export --date 2025-01-15    # Export for specific date
/// ```
public struct ScobyExportCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "scoby-export",
        abstract: "Export SCOBY system health report to markdown",
        discussion: """
        Generate a comprehensive system health report covering:
        - Log file analysis (errors, warnings, anomalies)
        - Crash reports from DiagnosticReports
        - Unusual log file growth
        - System observation snapshots

        The report is saved in markdown format for easy integration with
        other documentation or briefing systems.
        """
    )

    /// Date to analyze (defaults to today)
    @Option(
        name: .shortAndLong,
        help: "Date for the report (YYYY-MM-DD format, defaults to today)"
    )
    var date: String?

    /// Output file path
    @Option(
        name: .shortAndLong,
        help: "Output file path (defaults to ./logs/scoby-report-YYYY-MM-DD.md)"
    )
    var output: String?

    /// Verbose output
    @Flag(
        name: .shortAndLong,
        help: "Show detailed progress information"
    )
    var verbose: Bool = false

    /// Suppress output (useful for scripting)
    @Flag(
        name: .long,
        help: "Suppress all output except errors"
    )
    var quiet: Bool = false

    /// Include only critical issues
    @Flag(
        name: .long,
        help: "Include only errors and critical warnings"
    )
    var criticalOnly: Bool = false

    /// Scan custom log directories
    @Option(
        name: .long,
        help: "Additional log directories to scan (comma-separated)"
    )
    var logDirs: String?

    /// Maximum file size threshold (in MB) for log file analysis
    @Option(
        name: .long,
        help: "Maximum log file size to analyze in MB (default: 50, use 0 for unlimited)"
    )
    var maxSize: Int = 50

    public init() {}

    public func run() async throws {
        // Resolve date
        let reportDate = date.map { DateFormatter.yyyyMMdd.date(from: $0) ?? Date() } ?? Date()

        // Resolve output path
        let outputPath = resolveOutputPath(for: reportDate)

        // Check provider status
        let provider = ScobyProvider()
        let status = try await provider.checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        if !quiet {
            print("🔍 Generating SCOBY system health report...")
            if verbose {
                print("   Date: \(DateFormatter.yyyyMMdd.string(from: reportDate))")
                print("   Output: \(outputPath)")
                print("   Max file size: \(maxSize > 0 ? "\(maxSize) MB" : "unlimited")")
            }
        }

        // Generate report
        var reportContent = try await provider.generateMarkdownReport(for: reportDate)

        // Apply filters if requested
        if criticalOnly {
            reportContent = filterCriticalContent(from: reportContent)
            if verbose && !quiet {
                print("   ⚠️ Filtering to critical issues only")
            }
        }

        // Write to file
        try writeReport(reportContent, to: outputPath)

        // Output results
        if !quiet {
            print("")
            print("✅ Report saved to: \(outputPath)")

            // Provide summary
            let lineCount = reportContent.components(separatedBy: .newlines).count
            let errorCount = reportContent.components(separatedBy: .newlines).filter { $0.contains("❌") }.count
            let warningCount = reportContent.components(separatedBy: .newlines).filter { $0.contains("⚠️") }.count

            print("   Lines: \(lineCount)")
            if errorCount > 0 {
                print("   Errors: \(errorCount) 🔴")
            }
            if warningCount > 0 {
                print("   Warnings: \(warningCount) 🟡")
            }
            if errorCount == 0 && warningCount == 0 {
                print("   Status: Clean ✅")
            }
        }
    }

    // MARK: - Helper Methods

    /// Resolve the output file path based on configuration.
    private func resolveOutputPath(for date: Date) -> String {
        if let customPath = output {
            // Handle tilde expansion
            let expandedPath = NSString(string: customPath).expandingTildeInPath

            // If path is a directory, append default filename
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory),
               isDirectory.boolValue {
                let filename = "scoby-report-\(DateFormatter.yyyyMMdd.string(from: date)).md"
                return "\(expandedPath)/\(filename)"
            }

            // Ensure directory exists
            let directory = NSString(string: expandedPath).deletingLastPathComponent
            if !FileManager.default.fileExists(atPath: directory) {
                try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
            }

            return expandedPath
        }

        // Default: ./logs/scoby-report-YYYY-MM-DD.md
        let logsDir = "./logs"
        if !FileManager.default.fileExists(atPath: logsDir) {
            try? FileManager.default.createDirectory(atPath: logsDir, withIntermediateDirectories: true)
        }

        let filename = "scoby-report-\(DateFormatter.yyyyMMdd.string(from: date)).md"
        return "\(logsDir)/\(filename)"
    }

    /// Write report content to file.
    private func writeReport(_ content: String, to path: String) throws {
        let url = URL(fileURLWithPath: path)

        // Ensure parent directory exists
        let parentDir = url.deletingLastPathComponent().path
        if !FileManager.default.fileExists(atPath: parentDir) {
            try FileManager.default.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
        }

        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Filter report content to include only critical issues.
    private func filterCriticalContent(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var filteredLines: [String] = []

        var inSection = false
        var keepSection = false

        for line in lines {
            // Section headers
            if line.hasPrefix("## ") {
                if inSection && keepSection {
                    // Keep the section we were processing
                }
                inSection = true

                // Determine if we should keep this section
                if line.contains("Error") || line.contains("Critical") {
                    keepSection = true
                    filteredLines.append(line)
                } else {
                    keepSection = false
                }
                continue
            }

            // Content within sections
            if inSection {
                if keepSection {
                    filteredLines.append(line)
                }
            } else {
                // Always keep non-section content (header, metadata)
                filteredLines.append(line)
            }
        }

        return filteredLines.joined(separator: "\n")
    }
}
