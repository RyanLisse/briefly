import MCP
import Logging

public actor BrieflyMCPServer {
    private let logger: Logger
    private let toolHandler: ToolHandler

    public init(logger: Logger = Logger(label: "com.steipete.briefly.mcp")) {
        self.logger = logger
        self.toolHandler = ToolHandler(logger: logger)
    }

    public func run() async throws {
        let server = Server(
            name: "briefly",
            version: "1.0.0",
            capabilities: .init(tools: .init())
        )

        await server.withMethodHandler(ListTools.self) { _ in
            await self.toolHandler.listTools()
        }

        await server.withMethodHandler(CallTool.self) { params in
            try await self.toolHandler.callTool(params)
        }

        let transport = StdioTransport()
        try await server.start(transport: transport)
    }
}
