import Foundation

public protocol RuuviLocalFactory {
    func createLocalSettings() -> RuuviLocalSettings
    func createLocalIDs() -> RuuviLocalIDs
    func createLocalConnections() -> RuuviLocalConnections
    func createLocalSyncState() -> RuuviLocalSyncState
}

public final class RuuviLocalFactoryImpl: RuuviLocalFactory {
    public init() {}

    public func createLocalSettings() -> RuuviLocalSettings {
        return RuuviLocalSettingsUserDefaults()
    }

    public func createLocalIDs() -> RuuviLocalIDs {
        return RuuviLocalIDsUserDefaults()
    }

    public func createLocalConnections() -> RuuviLocalConnections {
        return RuuviLocalConnectionsUserDefaults()
    }

    public func createLocalSyncState() -> RuuviLocalSyncState {
        return RuuviLocalSyncStateUserDefaults()
    }
}
