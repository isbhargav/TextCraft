import AppKit
import SwiftUI

@MainActor
final class ActionPanelController {
    private var panel: ActionPanel?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    var onActionSelected: ((AIAction) -> Void)?

    func show(near point: NSPoint) {
        dismiss()

        let view = ActionPanelView { [weak self] action in
            self?.onActionSelected?(action)
            self?.dismiss()
        }

        let hostingController = NSHostingController(rootView: view)
        let fittingSize = hostingController.sizeThatFits(in: NSSize(width: 300, height: 600))

        let panel = ActionPanel(contentRect: NSRect(
            x: point.x,
            y: point.y - fittingSize.height,
            width: fittingSize.width,
            height: fittingSize.height
        ))

        panel.contentViewController = hostingController

        if let screen = NSScreen.main {
            var frame = panel.frame
            let screenFrame = screen.visibleFrame
            if frame.maxX > screenFrame.maxX { frame.origin.x = screenFrame.maxX - frame.width }
            if frame.minX < screenFrame.minX { frame.origin.x = screenFrame.minX }
            if frame.minY < screenFrame.minY { frame.origin.y = screenFrame.minY }
            if frame.maxY > screenFrame.maxY { frame.origin.y = screenFrame.maxY - frame.height }
            panel.setFrame(frame, display: false)
        }

        panel.orderFrontRegardless()
        self.panel = panel

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.dismiss()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                Task { @MainActor in
                    self?.dismiss()
                }
                return nil
            }
            return event
        }
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }
}
