import AppKit
import SwiftUI

@MainActor
final class ChatWindowController {
    private var window: NSWindow?

    func show(session: ChatSession) {
        close()

        let viewModel = ChatViewModel(session: session)
        let chatView = ChatView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: chatView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController
        window.title = "TextCraft"
        window.center()
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 400, height: 300)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func close() {
        window?.close()
        window = nil
    }
}
