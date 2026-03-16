<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="TextCraft icon">
</p>

# TextCraft

A macOS menu bar app for AI-powered text manipulation. Select text in any app, hit a hotkey, and pick an action — fix grammar, rewrite, summarize, and more. The result is pasted back in place.

## Features

- **Menu bar app** — lives in the status bar, no dock icon
- **Global hotkey** — Cmd+Shift+X captures selected text from any app
- **Quick actions** — Fix Grammar, Rewrite, Summarize, Make Shorter, Make Longer, Explain
- **Custom prompts** — write your own prompt or edit the defaults
- **Chat mode** — open a chat window for freeform conversation with the AI
- **Paste-back** — transformed text is automatically pasted back into the source app
- **Text capture** — grabs selected text via Accessibility API with clipboard fallback

## Requirements

- macOS 14.0+
- Swift toolchain (comes with Xcode Command Line Tools: `xcode-select --install`)
- OpenAI API key

## Build

No Xcode project needed. Build entirely from the CLI:

```bash
./build.sh
```

This compiles all Swift sources with `swiftc` and assembles a proper `.app` bundle in `build/TextCraft.app`.

## Run

```bash
open build/TextCraft.app
```

## Install

```bash
cp -r build/TextCraft.app /Applications/
```

## Setup

1. Open Settings from the menu bar icon
2. Enter your OpenAI API key
3. Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)

## How It Works

1. Press Cmd+Shift+X while text is selected in any app.
2. TextCraft captures the selected text via the Accessibility API (or clipboard fallback).
3. A floating action panel appears with quick actions to choose from.
4. The selected text is sent to the OpenAI API with the action's system prompt.
5. The AI response is pasted back into the source app, replacing the selection.

## Project Structure

```
Sources/
  TextCraftApp.swift            App entry point (menu bar agent app)
  AppDelegate.swift             Hotkey registration, app lifecycle
  AppState.swift                Shared app state
  Constants.swift               App-wide constants and defaults
  HotkeyManager.swift           Global hotkey via Carbon Events
  TextCaptureService.swift      Grabs selected text from frontmost app
  PastebackService.swift        Pastes transformed text back into source app
  ActionPanel.swift             Floating action panel window
  ActionPanelController.swift   Action panel window controller
  ActionPanelView.swift         SwiftUI view for quick action picker
  AIAction.swift                Action definitions and system prompts
  OpenAIClient.swift            OpenAI API integration
  PromptBuilder.swift           Builds chat completion prompts
  ChatWindowController.swift    Chat window management
  ChatView.swift                SwiftUI chat interface
  ChatViewModel.swift           Chat business logic
  ChatMessage.swift             Chat message model
  ChatSession.swift             Chat session model
  MessageBubble.swift           Chat message bubble view
  KeychainService.swift         Secure API key storage
  SettingsView.swift            Preferences UI
Resources/
  Info.plist                    App configuration (LSUIElement agent app)
  AppIcon.icns                  App icon
build.sh                        CLI build script (no Xcode needed)
```

## License

MIT
