import Foundation
import Network

/// Monitors network reachability using NWPathMonitor.
/// Triggers sync when connectivity is restored.
@Observable
final class NetworkMonitor: @unchecked Sendable {
    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType: Sendable {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.kinexfit.networkmonitor")

    /// Callback fired when network becomes available after being unavailable.
    var onReconnect: (@Sendable () -> Void)?

    init() {
        monitor = NWPathMonitor()
    }

    /// Starts monitoring network status.
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let wasConnected = self?.isConnected ?? true
            let nowConnected = path.status == .satisfied

            Task { @MainActor in
                self?.isConnected = nowConnected
                self?.connectionType = self?.mapConnectionType(path) ?? .unknown

                // Fire reconnect callback when transitioning from disconnected to connected
                if !wasConnected && nowConnected {
                    self?.onReconnect?()
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// Stops monitoring.
    func stop() {
        monitor.cancel()
    }

    private func mapConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        }
        return .unknown
    }
}
