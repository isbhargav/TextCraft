import Carbon.HIToolbox
import AppKit

@MainActor
final class HotkeyManager {
    nonisolated(unsafe) private var hotkeyRef: EventHotKeyRef?
    nonisolated(unsafe) private var eventHandler: EventHandlerRef?
    private var callback: (@MainActor () -> Void)?

    fileprivate nonisolated(unsafe) static var current: HotkeyManager?
    fileprivate nonisolated(unsafe) static var storedCallback: (@MainActor () -> Void)?

    private static let hotkeySignature: FourCharCode = {
        let chars: [UInt8] = [
            UInt8(ascii: "T"),
            UInt8(ascii: "x"),
            UInt8(ascii: "C"),
            UInt8(ascii: "r"),
        ]
        return FourCharCode(chars[0]) << 24
            | FourCharCode(chars[1]) << 16
            | FourCharCode(chars[2]) << 8
            | FourCharCode(chars[3])
    }()

    private static let hotkeyID: UInt32 = 1

    func start(onTrigger callback: @escaping @MainActor () -> Void) {
        self.callback = callback
        HotkeyManager.current = self
        HotkeyManager.storedCallback = callback
        register()
    }

    func stop() {
        unregister()
        callback = nil
        HotkeyManager.current = nil
        HotkeyManager.storedCallback = nil
    }

    deinit {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        HotkeyManager.current = nil
        HotkeyManager.storedCallback = nil
    }

    // MARK: - Private

    private func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard status == noErr else { return }

        let hotkeyID = EventHotKeyID(
            signature: HotkeyManager.hotkeySignature,
            id: HotkeyManager.hotkeyID
        )

        let carbonModifiers: UInt32 = UInt32(cmdKey | shiftKey)

        RegisterEventHotKey(
            Constants.defaultHotkeyKeyCode,
            carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }

    private func unregister() {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}

// MARK: - Carbon Event Handler

private func hotkeyEventHandler(
    _: EventHandlerCallRef?,
    event: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else { return OSStatus(eventNotHandledErr) }

    var hotkeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )

    guard status == noErr else { return status }

    DispatchQueue.main.async { @MainActor in
        HotkeyManager.storedCallback?()
    }

    return noErr
}
