import Foundation
import RuuviVirtual
import RuuviStorage
import RuuviReactor
import RuuviPool
import RuuviPersistence
import BTKit

public enum RuuviDaemonError: Error {
    case virtualStorage(VirtualStorageError)
    case ruuviStorage(RuuviStorageError)
    case ruuviReactor(RuuviReactorError)
    case ruuviPool(RuuviPoolError)
    case ruuviPersistence(RuuviPersistenceError)
    case btkit(BTError)
}
