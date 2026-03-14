import AppKit
import Carbon.HIToolbox

enum Constants {
    static let appName = "TextCraft"
    static let defaultHotkeyKeyCode: UInt32 = UInt32(kVK_ANSI_X)
    static let defaultHotkeyModifiers: UInt32 = UInt32(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
    static let keychainServiceName = "com.textcraft.app"
    static let keychainAPIKeyAccount = "openai-api-key"
    static let openAIEndpoint = "https://api.openai.com/v1/chat/completions"
    static let openAIModel = "gpt-4o-mini"
}
