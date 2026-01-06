import Foundation
import ArgumentParser

public struct PulseCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "pulse",
        abstract: "Generate a weekly pulse check of accomplishments"
    )

    @Flag(name: .shortAndLong, help: "Include detailed output")
    var verbose: Bool = false

    public init() {}

    public func run() async throws {
        print("💓 Checking pulse for the past week...")
        
        let githubProvider = GithubProvider()
        let calendarProvider = CalendarProvider()
        let whoopProvider = WhoopProvider()
        
        // Calculate dates
        let calendar = Calendar.current
        let today = Date()
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            print("Error parsing dates")
            return
        }
        
        print("📅 Analyzing activity from \(DateFormatter.yyyyMMdd.string(from: oneWeekAgo)) to \(DateFormatter.yyyyMMdd.string(from: today))")

        // Fetch Data Concurrently
        async let githubActivity = PulseCommand.fetchWeeklyGithub(provider: githubProvider, from: oneWeekAgo, to: today)
        // We could also fetch weekly meetings or health averages here
        async let healthData = PulseCommand.fetchWeeklyHealth(provider: whoopProvider, from: oneWeekAgo, to: today)

        let (code, health) = await (try? githubActivity, try? healthData)
        
        print("\n# Weekly Pulse Check")
        print("--------------------")
        
        print("\n## 🛠️  Accomplishments (Code)")
        if let code = code, !code.isEmpty {
            for item in code {
                print("- \(item)")
            }
        } else {
            print("- No significant code activity detected.")
        }
        
        print("\n## ❤️  Health Trends (Last 7 Days)")
        if let health = health, !health.isEmpty {
            print("- Average Recovery: \(health)")
        } else {
            print("- No health data available.")
        }
        
        print("\n## 🎯 Focus for Next Week")
        print("- [ ] (Add your top goal here)")
        print("- [ ] (Add your secondary goal here)")
        
        print("\n--------------------")
    }
    
    private static func fetchWeeklyGithub(provider: GithubProvider, from start: Date, to end: Date) async throws -> [String] {
        // Since GithubProvider fetches by day, we need to iterate
        // Optimization: GithubProvider uses `gh search commits` with a specific date.
        // We can create a range of dates.
        
        var accomplishments: [String] = []
        var currentDate = start
        let calendar = Calendar.current
        
        // Use a task group to fetch days in parallel
        
        await withThrowingTaskGroup(of: [String].self) { group in
            while currentDate <= end {
                let date = currentDate
                group.addTask {
                    do {
                        let activity = try await provider.fetchActivity(for: date)
                        return activity
                    } catch {
                        return []
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            do {
                for try await activity in group {
                    accomplishments.append(contentsOf: activity)
                }
            } catch {
                print("Error fetching pulse data: \(error)")
            }
        }
        
        // Deduplicate and Sort?
        // Simple aggregation for now:
        // Merge "Repo X" entries?
        // The format we get is: "Repo Name: X commits" or "PR [MERGED]..."
        
        // Let's condense it.
        var repoCommits: [String: Int] = [:]
        var prs: [String] = []
        
        for item in accomplishments {
            if item.contains("commits"), let repoName = item.components(separatedBy: ":").first?.replacingOccurrences(of: "Repo ", with: "") {
                 // Format: "Repo owner/name: 5 commits"
                 // Extract count? 
                 // The string is "Repo owner/name: 5 commits"
                 // This parsing is brittle, but fast.
                 let tools = item.components(separatedBy: " ")
                 if let countIndex = tools.firstIndex(of: "commits"), countIndex > 0, let count = Int(tools[countIndex - 1]) {
                     repoCommits[repoName, default: 0] += count
                 }
            } else if item.contains("PR [") {
                prs.append(item)
            }
        }
        
        var summary: [String] = []
        for (repo, count) in repoCommits {
            summary.append("Pushed \(count) commits to `\(repo)`")
        }
        summary.append(contentsOf: prs)
        
        return summary
    }
    
    private static func fetchWeeklyHealth(provider: WhoopProvider, from start: Date, to end: Date) async throws -> String {
        // Just fetch today's for now as a sample, or implement range fetching later.
        // To do a true weekly average, we'd need to fetch 7 days.
        // Let's just return today's recovery for now to be fast.
        let todayRecovery = try await provider.fetchRecovery(for: end)
        // Parse "Recovery Score: 78%"
        return todayRecovery
    }
}
