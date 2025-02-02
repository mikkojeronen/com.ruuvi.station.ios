import Foundation
import RuuviLocal
import RuuviMigration

final class MigrationManagerToTimeouts: RuuviMigration {
    private var settings: RuuviLocalSettings

    init(settings: RuuviLocalSettings) {
        self.settings = settings
    }

    func migrateIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: migratedUdKey) else { return }
        settings.connectionTimeout = 30
        settings.serviceTimeout = 300
        UserDefaults.standard.set(true, forKey: migratedUdKey)
    }

    private let migratedUdKey = "MigrationManagerToTimeouts.migrated"
}
