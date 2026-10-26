/// butterkit-mcp: the MCP server that AI hosts (Claude Code, Cursor, ...) spawn.
///
/// This process owns the MCP session with the host over stdin/stdout, and
/// forwards tool calls to the running ButterKit.app over a Unix domain socket.
/// Unlike the app, this process's lifetime is controlled by the host — so the
/// host-facing session survives ButterKit quitting, updating, or relaunching:
///
///   - `tools/list` is answered from the live app when reachable, otherwise
///     from the catalog snapshot ButterKit writes to the App Group container.
///   - `tools/call` lazily launches ButterKit when it isn't running (unless the
///     user disabled agent-initiated launch in ButterKit Settings → MCP), and
///     reports failures as tool errors instead of killing the transport.
///   - A supervisor loop quietly reconnects when ButterKit comes back, then
///     emits `notifications/tools/list_changed` so hosts refresh their catalog.
///
/// Usage:
///   butterkit-mcp            Start the server
///   butterkit-mcp --version  Print version and exit
///   butterkit-mcp --help     Print usage and exit

import Foundation
import MCP

if CommandLine.arguments.contains("--version") {
    print("butterkit-mcp \(ShimEnvironment.shimVersion)")
    exit(0)
}

if CommandLine.arguments.contains("--help") {
    fputs("""
    butterkit-mcp \(ShimEnvironment.shimVersion)
    MCP server for ButterKit

    MCP hosts should spawn this binary and communicate via stdin/stdout.
    It connects to ButterKit.app on demand and launches it for tool calls
    when needed (disable in ButterKit Settings > MCP).

    Options:
      --auto-launch  Accepted for backwards compatibility (launching on demand
                     is now the default behavior)
      --version      Print version and exit
      --help         Print this help and exit

    Socket path:  \(ShimEnvironment.socketPath())
    Tool catalog: \(ShimEnvironment.catalogPath())

    """, stderr)
    exit(0)
}

signal(SIGPIPE, SIG_IGN)

let catalog = ToolCatalog()
await catalog.loadFromDisk()

let appConnection = AppConnection(catalog: catalog)

let server = Server(
    name: "ButterKit",
    version: await catalog.appVersion ?? ShimEnvironment.shimVersion,
    capabilities: .init(
        logging: .init(),
        tools: .init(listChanged: true)
    )
)

await appConnection.setOnConnected {
    try? await server.notify(ToolListChangedNotification.message())
}

await server.withMethodHandler(ListTools.self) { _ in
    if let live = await appConnection.liveTools() {
        return .init(tools: live)
    }
    return .init(tools: await catalog.tools)
}

await server.withMethodHandler(CallTool.self) { params in
    do {
        let (content, isError) = try await appConnection.callTool(
            name: params.name,
            arguments: params.arguments
        )
        return .init(content: content, isError: isError)
    } catch let unreachable as AppConnection.AppUnreachable {
        return .init(content: [.text(unreachable.advice)], isError: true)
    } catch {
        return .init(content: [.text("ButterKit tool call failed: \(error)")], isError: true)
    }
}

await server.withMethodHandler(ListResources.self) { _ in
    .init(resources: [])
}

await server.withMethodHandler(ListResourceTemplates.self) { _ in
    .init(templates: [])
}

try await server.start(transport: StdioTransport()) { clientInfo, _ in
    await appConnection.setHostIdentity(name: clientInfo.name, version: clientInfo.version)
}

await appConnection.startSupervisor()
await server.waitUntilCompleted()
await appConnection.shutdown()
