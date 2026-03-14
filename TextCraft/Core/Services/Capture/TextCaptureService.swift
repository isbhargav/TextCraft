import AppKit
import ApplicationServices

@MainActor
final class TextCaptureService {
    struct CaptureResult {
        let text: String
        let sourceAppBundleID: String?
        let sourceAppPID: pid_t
    }

    func captureSelectedText() async -> CaptureResult? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return nil }

        let bundleID = frontApp.bundleIdentifier
        let pid = frontApp.processIdentifier

        if let text = getSelectedTextViaAccessibility(pid: pid), !text.isEmpty {
            return CaptureResult(text: text, sourceAppBundleID: bundleID, sourceAppPID: pid)
        }

        if let text = await getSelectedTextViaClipboard(), !text.isEmpty {
            return CaptureResult(text: text, sourceAppBundleID: bundleID, sourceAppPID: pid)
        }

        return nil
    }

    // MARK: - Accessibility

    private func getSelectedTextViaAccessibility(pid: pid_t) -> String? {
        let appElement = AXUIElementCreateApplication(pid)

        var focusedElement: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard focusResult == .success, let element = focusedElement else { return nil }

        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            element as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        guard textResult == .success, let text = selectedText as? String else { return nil }
        return text
    }

    // MARK: - Clipboard Fallback

    private func getSelectedTextViaClipboard() async -> String? {
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        let oldChangeCount = pasteboard.changeCount

        simulateKeyPress(keyCode: 8, modifiers: .maskCommand) // kVK_ANSI_C

        try? await Task.sleep(for: .milliseconds(100))

        let newChangeCount = pasteboard.changeCount
        let newText = pasteboard.string(forType: .string)

        // Restore old clipboard
        if let oldContents {
            pasteboard.clearContents()
            pasteboard.setString(oldContents, forType: .string)
        }

        guard newChangeCount != oldChangeCount else { return nil }
        return newText
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
