import Foundation

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    var apiKey: String
    var endpoint: String
    var model: String
    var selectedText: String = ""
    var sourceAppBundleID: String?
    var sourceAppPID: pid_t = 0
    var chatSession: ChatSession?
    var isActionPanelVisible: Bool = false

    private init() {
        self.apiKey = AppState.loadAPIKeyFromKeychain() ?? ""
        self.endpoint = UserDefaults.standard.string(forKey: "endpoint") ?? Constants.defaultEndpoint
        self.model = UserDefaults.standard.string(forKey: "model") ?? Constants.defaultModel
    }

    func updateSelectedText(_ text: String, from bundleID: String? = nil) {
        selectedText = text
        sourceAppBundleID = bundleID
    }

    func clearSelection() {
        selectedText = ""
        sourceAppBundleID = nil
    }

    func startNewChatSession(action: AIAction = .custom) {
        chatSession = ChatSession(selectedText: selectedText, action: action)
    }

    private static func loadAPIKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.textcraft.app.apikey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        return key
    }
}
