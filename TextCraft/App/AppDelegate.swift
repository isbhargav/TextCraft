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
        // Capture frontmost app and mouse location immediately, before any async work
        let frontApp = NSWorkspace.shared.frontmostApplication
        let mouseLocation = NSEvent.mouseLocation

        Task { @MainActor [weak self] in
            guard let self, let frontApp else { return }

            guard let result = await textCaptureService.captureSelectedText(from: frontApp) else {
                return
            }

            let appState = AppState.shared
            appState.updateSelectedText(result.text, from: result.sourceAppBundleID)
            appState.sourceAppPID = result.sourceAppPID

            actionPanelController.show(near: mouseLocation)
        }
    }
}
