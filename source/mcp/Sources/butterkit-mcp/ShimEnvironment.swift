/// Path resolution and policy for the butterkit-mcp shim.
///
/// Env overrides (used by the test harness; harmless in production):
///   BUTTERKIT_MCP_SOCKET   absolute path to the app's Unix domain socket
///   BUTTERKIT_MCP_CATALOG  absolute path to the tools catalog JSON
///   BUTTERKIT_MCP_NO_LAUNCH=1  never launch ButterKit

import Foundation

enum ShimEnvironment {
    static let shimVersion = "2.0.0"
    static let appGroupID = "group.app.butterkit"

    /// Seconds to wait for the app's socket after launching it.
    static let launchConnectTimeout: TimeInterval = 20
    /// Minimum seconds between agent-initiated launch attempts.
    static let launchCooldown: TimeInterval = 60

    static func socketPath() -> String {
        if let override = ProcessInfo.processInfo.environment["BUTTERKIT_MCP_SOCKET"], !override.isEmpty {
            return override
        }

        // The app creates the socket in its App Group container. Resolve the known
        // container path directly so this works whether or not the shim's process
        // context can use containerURL(forSecurityApplicationGroupIdentifier:).
        let groupContainer = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Group Containers/\(appGroupID)")
        let groupSocket = groupContainer.appendingPathComponent("mcp.sock").path
        if FileManager.default.fileExists(atPath: groupSocket) {
            return groupSocket
        }

        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return url.appendingPathComponent("mcp.sock").path
        }

        // Fallback for non-sandboxed development builds
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("ButterKit")
            .appendingPathComponent("mcp.sock")
            .path
    }

    static func catalogPath() -> String {
        if let override = ProcessInfo.processInfo.environment["BUTTERKIT_MCP_CATALOG"], !override.isEmpty {
            return override
        }
        return URL(fileURLWithPath: socketPath())
            .deletingLastPathComponent()
            .appendingPathComponent("mcp-tools.json")
            .path
    }

    /// Whether the shim may launch ButterKit when a tool call arrives and the app
    /// isn't running. Users opt out via ButterKit Settings → MCP; absent any stored
    /// preference, launching is allowed (the user already consented by enabling MCP
    /// and configuring their agent).
    static func launchAllowed() -> Bool {
        if ProcessInfo.processInfo.environment["BUTTERKIT_MCP_NO_LAUNCH"] == "1" {
            return false
        }
        if let defaults = UserDefaults(suiteName: appGroupID),
           defaults.object(forKey: "mcp_allow_agent_launch") != nil {
            return defaults.bool(forKey: "mcp_allow_agent_launch")
        }
        return true
    }

    /// The ButterKit.app bundle that contains this shim. Launching by bundle URL
    /// (rather than `open -a ButterKit`) keeps dev builds and renamed apps working.
    static func containingAppBundleURL() -> URL? {
        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let candidate = executable
            .deletingLastPathComponent() // MacOS
            .deletingLastPathComponent() // Contents
            .deletingLastPathComponent() // ButterKit.app
        return candidate.pathExtension == "app" ? candidate : nil
    }

    static func log(_ message: String) {
        fputs("butterkit-mcp: \(message)\n", stderr)
    }
}
