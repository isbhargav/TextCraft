import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyManager = HotkeyManager()
    private let textCaptureService = TextCaptureService()
    private let actionPanelController = ActionPanelController()
    private let chatWindowController = ChatWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        actionPanelController.onActionSelected = { [weak self] action in
            guard let self else { return }
            let appState = AppState.shared
            appState.startNewChatSession(action: action)
            if let session = appState.chatSession {
                chatWindowController.show(session: session)
            }
        }

        hotkeyManager.start { [weak self] in
            self?.handleHotkeyTriggered()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.stop()
    }

    func openChat() {
        let appState = AppState.shared
        if let session = appState.chatSession {
            chatWindowController.show(session: session)
        }
    }

    private func handleHotkeyTriggered() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            guard let result = await textCaptureService.captureSelectedText() else {
                return
            }

            let appState = AppState.shared
            appState.updateSelectedText(result.text, from: result.sourceAppBundleID)
            appState.sourceAppPID = result.sourceAppPID

            let mouseLocation = NSEvent.mouseLocation
            actionPanelController.show(near: mouseLocation)
        }
    }
}
