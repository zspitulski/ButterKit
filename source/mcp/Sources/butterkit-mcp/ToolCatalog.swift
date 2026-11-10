/// The tool catalog lets the shim answer `tools/list` before ButterKit is running.
///
/// ButterKit writes a JSON snapshot of its tool definitions next to the socket
/// whenever its MCP service starts, so the snapshot always matches the app
/// version installed on disk. Once connected, the shim refreshes the catalog
/// from the live server, which then takes precedence.

import Foundation
import MCP

struct ToolCatalogFile: Codable {
    var schemaVersion: Int
    var appVersion: String?
    var generatedAt: String?
    var tools: [Tool]
}

actor ToolCatalog {
    private(set) var tools: [Tool] = []
    private(set) var appVersion: String?

    /// Loads the snapshot ButterKit wrote to the group container, if present.
    func loadFromDisk() {
        let path = ShimEnvironment.catalogPath()
        guard let data = FileManager.default.contents(atPath: path) else {
            ShimEnvironment.log("no tool catalog at \(path); tool list unavailable until ButterKit connects")
            return
        }
        do {
            let file = try JSONDecoder().decode(ToolCatalogFile.self, from: data)
            tools = file.tools
            appVersion = file.appVersion
            ShimEnvironment.log("loaded catalog of \(file.tools.count) tools (app \(file.appVersion ?? "unknown"))")
        } catch {
            ShimEnvironment.log("failed to decode tool catalog: \(error)")
        }
    }

    /// Replaces the catalog with the live tool list from a connected app.
    func update(tools liveTools: [Tool], appVersion version: String?) {
        tools = liveTools
        if let version {
            appVersion = version
        }
    }
}
