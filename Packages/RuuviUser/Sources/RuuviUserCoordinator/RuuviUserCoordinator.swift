import Foundation
import RuuviUser

final class RuuviUserCoordinator: RuuviUser {
    var apiKey: String? {
        get {
            return keychainService.ruuviUserApiKey
        }
        set {
            keychainService.ruuviUserApiKey = newValue
        }
    }
    var email: String? {
        get {
            return keychainService.userApiEmail
        }
        set {
            keychainService.userApiEmail = newValue
        }
    }
    var isAuthorized: Bool {
        get {
            return UserDefaults.standard.bool(forKey: isAuthorizedUDKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: isAuthorizedUDKey)
        }
    }

    private var keychainService: KeychainService
    private let isAuthorizedUDKey = "RuuviUserCoordinator.isAuthorizedUDKey"

    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }

    func login(apiKey: String) {
        self.apiKey = apiKey
        self.isAuthorized = true
    }

    func logout() {
        email = nil
        apiKey = nil
        isAuthorized = false
    }
}
