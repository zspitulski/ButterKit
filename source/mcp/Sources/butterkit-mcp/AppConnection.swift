/// Owns the reconnectable MCP connection to ButterKit.app. The separate
/// host-facing stdio server remains available while this connection is down.
import Foundation
import MCP
import Darwin

actor AppConnection {
    struct AppUnreachable: Error {
        let advice: String
    }

    private struct Session {
        let id: UUID
        let client: Client
        let transport: AppTransport
        var ready = false
        var activeToolCalls = 0
        var lastToolFinished: ContinuousClock.Instant?
    }

    private enum DeadlineKind {
        case setup, health
    }

    private struct ConnectionTimedOut: Error {}

    private let catalog: ToolCatalog
    private let clock = ContinuousClock()
    private let setupTimeout: Duration = .seconds(10)
    private let healthTimeout: Duration = .seconds(10)
    private var connection: Session?
    private var supervisor: Task<Void, Never>?
    private var stopped = false
    private var lastLaunchAttempt: ContinuousClock.Instant?
    private var hostName = "butterkit-mcp"
    private var hostVersion = ShimEnvironment.shimVersion
    private var onConnected: (@Sendable () async -> Void)?

    init(catalog: ToolCatalog) {
        self.catalog = catalog
    }

    func setOnConnected(_ handler: @escaping @Sendable () async -> Void) {
        onConnected = handler
    }

    func setHostIdentity(name: String, version: String) {
        guard !name.isEmpty else { return }
        hostName = name
        hostVersion = version.isEmpty ? "unknown" : version
    }

    func callTool(name: String, arguments: [String: Value]?) async throws -> (content: [Tool.Content], isError: Bool?) {
        try await ensureConnected(allowLaunch: true)
        try Task.checkCancellation()
        guard let session = connection, session.ready, !stopped else {
            throw AppUnreachable(advice: "ButterKit isn't reachable. Launch ButterKit and retry.")
        }
        connection?.activeToolCalls += 1
        defer {
            if connection?.id == session.id {
                connection?.activeToolCalls -= 1
                connection?.lastToolFinished = clock.now
            }
        }
        do {
            // No operation deadline or automatic replay: exports, translation,
            // and uploads can take much longer than connection setup.
            return try await session.client.callTool(name: name, arguments: arguments)
        } catch {
            await teardown(id: session.id, reason: "connection lost during '\(name)'")
            throw AppUnreachable(advice: """
                Connection to ButterKit was lost while running '\(name)'. ButterKit may have quit or restarted. \
                The operation may or may not have completed — check state (e.g. with a list tool), then retry.
                """)
        }
    }

    func liveTools() async -> [Tool]? {
        guard await attemptConnect() else { return nil }
        // Definitions are static for an app session. The live catalog is fetched
        // during setup and refreshed on reconnect, without competing with tools.
        return await catalog.tools
    }

    func startSupervisor() {
        guard supervisor == nil, !stopped else { return }
        supervisor = Task { [weak self] in
            var idleDelay: Duration = .seconds(2)
            while !Task.isCancelled {
                guard let self else { return }
                if await self.stopped { return }
                if await self.connection?.ready == true {
                    idleDelay = .seconds(2)
                    await self.healthCheck()
                    do { try await Task.sleep(for: .seconds(20)) }
                    catch { return }
                } else {
                    if await self.attemptConnect() { idleDelay = .seconds(2) }
                    do { try await Task.sleep(for: idleDelay) }
                    catch { return }
                    idleDelay = min(idleDelay * 2, .seconds(30))
                }
            }
        }
    }

    func shutdown() async {
        stopped = true
        supervisor?.cancel()
        supervisor = nil
        if let session = connection {
            await teardown(id: session.id, reason: "shim shutting down")
        }
    }

    private func ensureConnected(allowLaunch: Bool) async throws {
        if await attemptConnect() { return }
        try Task.checkCancellation()
        guard !stopped else { throw CancellationError() }
        guard allowLaunch else {
            throw AppUnreachable(advice: "ButterKit isn't running.")
        }
        guard ShimEnvironment.launchAllowed() else {
            throw AppUnreachable(advice: """
                ButterKit isn't running, and agent-initiated launch is disabled in ButterKit Settings → MCP. \
                Ask the user to open ButterKit, then retry.
                """)
        }
        if let last = lastLaunchAttempt,
           last.duration(to: clock.now) < .seconds(ShimEnvironment.launchCooldown) {
            throw AppUnreachable(advice: """
                ButterKit was launched recently but its MCP server isn't reachable. \
                Make sure 'Enable MCP Server' is on in ButterKit Settings → MCP, then retry.
                """)
        }

        lastLaunchAttempt = clock.now
        launchButterKit()
        let deadline = clock.now.advanced(by: .seconds(ShimEnvironment.launchConnectTimeout))
        while clock.now < deadline, !stopped {
            if await attemptConnect(deadline: deadline) { return }
            try await clock.sleep(until: min(deadline, clock.now.advanced(by: .milliseconds(500))))
        }
        throw AppUnreachable(advice: """
            ButterKit was launched but its MCP server didn't become reachable within \
            \(Int(ShimEnvironment.launchConnectTimeout)) seconds. Make sure 'Enable MCP Server' is on in \
            ButterKit Settings → MCP, then retry.
            """)
    }

    private func attemptConnect(deadline callerDeadline: ContinuousClock.Instant? = nil) async -> Bool {
        guard !stopped, !Task.isCancelled else { return false }
        if let current = connection {
            // Waiters don't own this attempt: cancellation must not tear down a
            // session another request is establishing. The owner's deadline does.
            while connection?.id == current.id, connection?.ready == false {
                if let callerDeadline, clock.now >= callerDeadline { return false }
                do { try await Task.sleep(for: .milliseconds(50)) }
                catch { return false }
                if stopped { return false }
            }
            return !stopped && connection?.ready == true
        }

        let deadline = min(callerDeadline ?? clock.now.advanced(by: setupTimeout), clock.now.advanced(by: setupTimeout))
        guard clock.now < deadline else { return false }
        let fd = Self.connectToSocket(path: ShimEnvironment.socketPath())
        guard fd >= 0 else { return false }
        let id = UUID()
        let client = Client(name: hostName, version: hostVersion)
        let transport = AppTransport(socketFD: fd) { [weak self] in
            await self?.teardown(id: id, reason: "app transport closed")
        }
        let session = Session(id: id, client: client, transport: transport)
        // Record before the first await: EOF, timeout, and shutdown must also
        // be able to disconnect a client whose initialization never completed.
        connection = session
        do {
            let (version, tools) = try await withDeadline(session: session, until: deadline, kind: .setup) {
                let result = try await client.connect(transport: transport)
                let (tools, _) = try await client.listTools()
                return (result.serverInfo.version, tools)
            }
            try Task.checkCancellation()
            guard connection?.id == id, !stopped else { throw CancellationError() }
            await catalog.update(tools: tools, appVersion: version)
            try Task.checkCancellation()
            guard connection?.id == id, !stopped else { throw CancellationError() }
            connection?.ready = true
            ShimEnvironment.log("connected to ButterKit \(version)")
            if let onConnected { Task { await onConnected() } }
            return true
        } catch {
            await teardown(id: id, reason: "connection setup failed")
            return false
        }
    }

    private func healthCheck() async {
        guard let session = connection, session.ready, session.activeToolCalls == 0 else { return }
        do {
            try await withDeadline(session: session, until: clock.now.advanced(by: healthTimeout), kind: .health) {
                try await session.client.ping()
            }
        } catch {
            await teardown(id: session.id, reason: "health check failed (ButterKit quit?)")
        }
    }

    private func withDeadline<T: Sendable>(
        session: Session,
        until deadline: ContinuousClock.Instant,
        kind: DeadlineKind,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withTaskCancellationHandler {
            try await withThrowingTaskGroup(of: T.self) { group in
                group.addTask { try await operation() }
                group.addTask {
                    var nextDeadline = deadline
                    while true {
                        try await self.clock.sleep(until: nextDeadline)
                        if await self.expire(session: session, kind: kind) {
                            throw ConnectionTimedOut()
                        }
                        nextDeadline = self.clock.now.advanced(by: self.healthTimeout)
                    }
                }
                defer { group.cancelAll() }
                return try await group.next()!
            }
        } onCancel: {
            // Task cancellation alone does not resume the SDK's pending request
            // continuations. Disconnect before the task group waits for them.
            Task { await self.teardown(id: session.id, reason: "connection operation cancelled") }
        }
    }

    private func expire(session: Session, kind: DeadlineKind) async -> Bool {
        guard let current = connection, current.id == session.id else { return true }
        if kind == .health {
            if current.activeToolCalls > 0 { return false }
            if let finished = current.lastToolFinished,
               finished.duration(to: clock.now) < healthTimeout { return false }
        }
        await teardown(id: session.id, reason: "\(kind) timed out")
        return true
    }

    private func teardown(id: UUID, reason: String) async {
        guard let session = connection, session.id == id else { return }
        connection = nil
        ShimEnvironment.log("disconnected from ButterKit: \(reason)")
        await session.transport.disconnect()
        await session.client.disconnect()
    }

    private static func connectToSocket(path: String) -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { return -1 }
        // A full local socket backlog must not block the actor or its deadlines.
        // If dialing cannot complete immediately, the supervisor retries later.
        guard fcntl(fd, F_SETFL, O_NONBLOCK) == 0,
              fcntl(fd, F_SETFD, FD_CLOEXEC) == 0 else {
            close(fd)
            return -1
        }
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = path.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
            close(fd)
            return -1
        }
        withUnsafeMutablePointer(to: &addr.sun_path) { sunPath in
            pathBytes.withUnsafeBufferPointer { src in
                UnsafeMutableRawPointer(sunPath).copyMemory(from: src.baseAddress!, byteCount: src.count)
            }
        }
        let result = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                connect(fd, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard result == 0 else {
            close(fd)
            return -1
        }
        return fd
    }

    private func launchButterKit() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        if let bundleURL = ShimEnvironment.containingAppBundleURL() {
            task.arguments = [bundleURL.path]
        } else {
            task.arguments = ["-a", "ButterKit"]
        }
        ShimEnvironment.log("launching ButterKit (\(task.arguments?.joined(separator: " ") ?? ""))")
        try? task.run()
    }
}
