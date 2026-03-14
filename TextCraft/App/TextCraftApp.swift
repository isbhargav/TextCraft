import SwiftUI

@main
struct TextCraftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("TextCraft", systemImage: "text.cursor") {
            Button("Open Chat") {
                appDelegate.openChat()
            }
            Divider()
            SettingsLink {
                Text("Settings...")
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
