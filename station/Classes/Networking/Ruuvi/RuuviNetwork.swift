import Foundation
import Future
import RuuviOntology

protocol RuuviNetwork {
    func load(ruuviTagId: String,
              mac: String,
              since: Date?,
              until: Date?) -> Future<[RuuviTagSensorRecord], RUError>
    func user() -> Future<UserApiUserResponse, RUError>
}

class RuuviNetworkFactory {
    var userApi: RuuviNetworkUserApi!

    func network() -> RuuviNetwork {
        return userApi
    }
}
