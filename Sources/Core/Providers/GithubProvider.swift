import Foundation

public struct GithubProvider: Provider {
    public let id = "github"
    public let dependencyId = "gh"
    private let executor = ShellExecutor()

    public init() {}

    public func checkStatus() async throws -> ProviderStatus {
        let isPresent = await DependencyManager.shared.verifyPresence(of: dependencyId)
        guard isPresent else { return .missingDependency }
        
        do {
            let output = try await executor.execute(dependencyId, arguments: ["auth", "status"])
            if output.contains("Logged in to github.com") {
                return .ready
            } else {
                return .unauthenticated(instructions: "Please run 'gh auth login' in your terminal.")
            }
        } catch {
             // gh auth status exits with 1 if not logged in, catch that
            return .unauthenticated(instructions: "Please run 'gh auth login' in your terminal.")
        }
    }

    public func fetchActivity(for date: Date) async throws -> [String] {
        let status = try await checkStatus()
        guard case .ready = status else {
            throw ProviderError.notReady(status)
        }

        let dateString = DateFormatter.yyyyMMdd.string(from: date)
        
        // Search commits
        let commitsOutput = try await executor.execute(
            dependencyId,
            arguments: ["search", "commits", "--author", "@me", "--committer-date", dateString, "--json", "commit,repository"],
            timeout: 15.0
        )
        
        var activity: [String] = []

        if let data = commitsOutput.data(using: .utf8),
           let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            
            // Group by repository
            var repoCommits: [String: [String]] = [:]
            
            for item in items {
                guard let commit = item["commit"] as? [String: Any],
                      let message = commit["message"] as? String,
                      let repository = item["repository"] as? [String: Any],
                      let repoName = repository["fullName"] as? String else {
                    continue
                }
                
                // First line of commit message only
                let shortMessage = message.components(separatedBy: .newlines).first ?? message
                repoCommits[repoName, default: []].append(shortMessage)
            }
            
            for (repo, messages) in repoCommits {
                activity.append("Repo \(repo): \(messages.count) commits")
                messages.prefix(3).forEach { msg in
                    activity.append("  - \(msg)")
                }
                if messages.count > 3 {
                    activity.append("  - ... and \(messages.count - 3) more")
                }
            }
        }
        
        // Search PRs (updated today)
        let prsOutput = try await executor.execute(
            dependencyId,
            arguments: ["search", "prs", "--author", "@me", "--updated", dateString, "--json", "title,repository,state,url"],
            timeout: 15.0
        )
        
        if let data = prsOutput.data(using: .utf8),
           let items = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            
            for item in items {
                guard let title = item["title"] as? String,
                      let state = item["state"] as? String,
                      let repository = item["repository"] as? [String: Any],
                      let repoName = repository["fullName"] as? String else {
                    continue
                }
                activity.append("PR [\(state)] in \(repoName): \(title)")
            }
        }
        
        return activity
    }
}

