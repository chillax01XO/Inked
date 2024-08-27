import Foundation
import LocalAuthentication

class PasscodeManager {
    static let shared = PasscodeManager()
    private let passcodeKey = "AppPasscode"
    private let isFaceIDAllowedKey = "isFaceIDAllowed"
    
    private init() {}

    func savePasscode(_ passcode: String) {
        UserDefaults.standard.set(passcode, forKey: passcodeKey)
    }

    func getPasscode() -> String? {
        return UserDefaults.standard.string(forKey: passcodeKey)
    }

    func deletePasscode() {
        UserDefaults.standard.removeObject(forKey: passcodeKey)
    }

    func isPasscodeSet() -> Bool {
        return getPasscode() != nil
    }
    
    func isFaceIDAllowed() -> Bool {
        return UserDefaults.standard.bool(forKey: isFaceIDAllowedKey)
    }
    
    func setFaceIDAllowed(_ allowed: Bool) {
        UserDefaults.standard.set(allowed, forKey: isFaceIDAllowedKey)
    }

    func authenticateUser(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate with Face ID"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success, authenticationError)
                }
            }
        } else {
            completion(false, error)
        }
    }
}
