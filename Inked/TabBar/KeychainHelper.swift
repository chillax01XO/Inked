import Security

class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func savePassword(_ password: String) {
        let data = Data(password.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "appPassword",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrievePassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "appPassword",
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &item)

        guard let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
