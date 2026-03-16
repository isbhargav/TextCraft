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
        KeychainService.retrieve(key: Constants.keychainAPIKeyAccount)
    }
}
