import AppKit

@MainActor
final class PastebackService {
    func insertText(_ text: String, into appPID: pid_t) async {
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        if let app = NSRunningApplication(processIdentifier: appPID) {
            app.activate()
            try? await Task.sleep(for: .milliseconds(200))
        }

        simulateKeyPress(keyCode: 9, modifiers: .maskCommand) // kVK_ANSI_V

        try? await Task.sleep(for: .milliseconds(300))

        if let oldContents {
            pasteboard.clearContents()
            pasteboard.setString(oldContents, forType: .string)
        }
    }

    private func simulateKeyPress(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = modifiers
        keyUp?.flags = modifiers
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
