# butterkit-mcp

The source of `butterkit-mcp`, the small program your AI tool launches when it talks to ButterKit. It ships inside the app at `ButterKit.app/Contents/MacOS/butterkit-mcp`, and these are the same Swift files it's built from.

It's published so you can read exactly what runs on your Mac when you connect an agent. You don't need to build it to use ButterKit: point your MCP config at the copy inside the app (setup is in the [main README](../README.md#connect-your-ai-agent)).

## What it does

`butterkit-mcp` is a bridge with no design logic of its own.

1. Your AI tool starts it and speaks MCP over stdin and stdout.
2. It forwards each tool call to ButterKit.app over a local Unix domain socket in the app's group container.
3. It sends the result back to your AI tool.

Nothing leaves your Mac. The bridge opens no network connections, reads nothing outside ButterKit's own folders, and saves nothing (it only logs to stderr).

A few details that make it pleasant to live with:

- **ButterKit doesn't need to be open first.** Until the app is reachable, the tool list comes from a snapshot ButterKit writes next to the socket (`mcp-tools.json`).
- **It can launch ButterKit for you.** The first tool call opens the app, unless you turn off "Allow agents to launch ButterKit" in **ButterKit > Settings > MCP**.
- **It survives restarts.** If ButterKit quits or updates mid-session, the bridge reconnects on its own and tells your AI tool to refresh the tool list. Your AI tool never needs restarting.

## Files

| File | What it is |
| --- | --- |
| [`Sources/butterkit-mcp/main.swift`](Sources/butterkit-mcp/main.swift) | Starts the MCP server your AI tool talks to |
| [`Sources/butterkit-mcp/AppConnection.swift`](Sources/butterkit-mcp/AppConnection.swift) | Connects to ButterKit, launches it when allowed, and reconnects after restarts |
| [`Sources/butterkit-mcp/AppTransport.swift`](Sources/butterkit-mcp/AppTransport.swift) | Carries MCP messages over the local socket |
| [`Sources/butterkit-mcp/ToolCatalog.swift`](Sources/butterkit-mcp/ToolCatalog.swift) | Serves the tool list while ButterKit is closed |
| [`Sources/butterkit-mcp/ShimEnvironment.swift`](Sources/butterkit-mcp/ShimEnvironment.swift) | Socket and catalog paths, launch policy and logging |
| [`butterkit-mcp.entitlements`](butterkit-mcp.entitlements) | The sandbox entitlements the shipped binary is signed with |

## Build it yourself

Requires macOS 26 and Swift 6.

```bash
swift build -c release
.build/release/butterkit-mcp --version
```

`Package.resolved` pins the same package versions the app is built with, including the [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) 0.12.0. A local build isn't signed or sandboxed like the shipped copy, so use the one inside ButterKit.app for everyday work.

For testing, three environment variables override the defaults:

| Variable | Effect |
| --- | --- |
| `BUTTERKIT_MCP_SOCKET` | Absolute path to the app's socket |
| `BUTTERKIT_MCP_CATALOG` | Absolute path to the tool catalog JSON |
| `BUTTERKIT_MCP_NO_LAUNCH=1` | Never launch ButterKit |

## License

MIT, like the rest of this repo. See [LICENSE](../LICENSE).
