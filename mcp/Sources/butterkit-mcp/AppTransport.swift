import Foundation
import Logging
import MCP
import System
import Darwin

/// Adapts the app socket to the SDK's newline-delimited transport.
///
/// MCP Swift SDK 0.12.x loops over an already-finished receive stream on EOF
/// (upstream issue #256), and does not fail outstanding client requests. Finish
/// with an error and notify the session owner so it can disconnect the client.
actor AppTransport: Transport {
    enum ConnectionClosed: Error {
        case closed
    }

    nonisolated let logger: Logger
    private let underlying: StdioTransport
    private let stream: AsyncThrowingStream<Data, Error>
    private let continuation: AsyncThrowingStream<Data, Error>.Continuation
    private let onClose: @Sendable () async -> Void
    private var socketFD: Int32?
    private var reader: Task<Void, Never>?
    private var closed = false
    private var started = false
    private var connecting = false
    private var underlyingDisconnected = false
    private var activeWrites = 0

    init(socketFD: Int32, onClose: @escaping @Sendable () async -> Void) {
        self.socketFD = socketFD
        self.onClose = onClose
        underlying = StdioTransport(
            input: FileDescriptor(rawValue: socketFD),
            output: FileDescriptor(rawValue: socketFD)
        )
        logger = underlying.logger
        (stream, continuation) = AsyncThrowingStream.makeStream()
    }

    deinit {
        if let socketFD { Darwin.close(socketFD) }
    }

    func connect() async throws {
        guard !closed else { throw ConnectionClosed.closed }
        guard !started else { return }
        started = true
        connecting = true
        defer {
            connecting = false
            closeSocketIfDrained()
        }
        do {
            try await underlying.connect()
            guard !closed else {
                await underlying.disconnect()
                throw ConnectionClosed.closed
            }
        } catch {
            await finish()
            throw error
        }

        reader = Task {
            do {
                for try await data in await underlying.receive() {
                    guard !closed, !Task.isCancelled else { break }
                    continuation.yield(data)
                }
            } catch {
                // EOF and read failures have the same session cleanup path.
            }
            await finish()
        }
    }

    func receive() -> AsyncThrowingStream<Data, Error> { stream }

    func send(_ data: Data) async throws {
        guard !closed else { throw ConnectionClosed.closed }
        activeWrites += 1
        defer {
            activeWrites -= 1
            closeSocketIfDrained()
        }
        do {
            try await underlying.send(data)
        } catch {
            await finish()
            throw error
        }
    }

    func disconnect() async { await finish() }

    private func finish() async {
        guard !closed else { return }
        closed = true
        // Unblock pending writes before releasing the descriptor. An SDK write
        // may be suspended on EAGAIN; it must never resume on a reused fd.
        if let socketFD { Darwin.shutdown(socketFD, SHUT_RDWR) }
        reader?.cancel()
        reader = nil
        continuation.finish(throwing: ConnectionClosed.closed)
        // Do not await the owner: Client.disconnect() waits for its receive task.
        Task { await onClose() }
        await underlying.disconnect()
        underlyingDisconnected = true
        closeSocketIfDrained()
    }

    private func closeSocketIfDrained() {
        guard closed, underlyingDisconnected, !connecting, activeWrites == 0, let socketFD else { return }
        self.socketFD = nil
        Darwin.close(socketFD)
    }
}
