# TextCraft — Requirements

## Overview

TextCraft is a lightweight, system-wide text utility that lets users transform selected text using AI. It activates via a global hotkey, presents quick-action options, and opens a minimal chat window powered by OpenAI. The user can refine results conversationally and insert the final text back into the original application.

---

## Core Workflow

1. **Select text** in any application.
2. **Press a global hotkey** (e.g., `Cmd+Shift+X`).
3. A **popup appears** near the cursor with preset actions:
   - Fix Grammar
   - Rewrite
   - Summarize
   - Make Shorter
   - Make Longer
   - Explain
   - Custom Prompt
4. **User picks an action** → a chat window opens with the selected text and chosen action sent to OpenAI.
5. **AI response appears** in the chat window.
6. The user can:
   - **Insert** the response — replaces the originally selected text and closes the window.
   - **Continue chatting** — refine or ask follow-ups in the same conversation.
   - **Click any previous response** to insert that version instead.

---

## Functional Requirements

### F1 — Global Hotkey
- Register a system-wide hotkey that works regardless of the focused application.
- Capture the currently selected text (via clipboard: copy → read → restore).

### F2 — Action Popup
- Show a floating, minimal popup listing preset actions.
- Popup appears near the text cursor or mouse pointer.
- Dismiss on `Esc` or clicking outside.
- Support a "Custom Prompt" option where the user types a freeform instruction.

### F3 — Chat Window
- Opens after an action is selected.
- Displays the conversation: user messages and AI responses.
- Each AI response has an **Insert** button.
- Text input at the bottom for follow-up messages.
- Dismiss on `Esc` or a close button.

### F4 — OpenAI Integration
- Send the selected text + action as a system/user prompt to OpenAI Chat Completions API.
- Stream the response for fast feedback.
- Maintain conversation context for follow-ups within the same session.

### F5 — Text Insertion
- When the user clicks **Insert** on any AI response:
  - Paste the chosen text back into the original application (via clipboard: save → paste → restore).
  - Close the chat window.

### F6 — Configuration
- User-configurable OpenAI API key (stored securely).
- Configurable hotkey.
- Option to add/edit/remove preset actions and their prompts.

---

## Non-Functional Requirements

- **Minimal UI** — clean, distraction-free, no unnecessary chrome.
- **Fast** — popup appears instantly; responses stream in real-time.
- **Lightweight** — low memory and CPU footprint when idle.
- **Privacy** — no data stored beyond the active session; API key stored in system keychain.
- **Cross-app** — works with any application that supports standard text selection.

---

## Tech Stack

| Layer        | Choice                              |
|------------- |-------------------------------------|
| Framework    | Native macOS (SwiftUI)              |
| Language     | Swift                               |
| AI           | OpenAI Chat Completions API         |
| Hotkey       | Global hotkey via CGEvent tap       |
| Clipboard    | NSPasteboard                        |
| Key storage  | macOS Keychain (Security framework) |
| Networking   | URLSession (streaming via SSE)      |

---

## Out of Scope (v1)

- Multiple AI provider support.
- Conversation history / persistence.
- Plugin or extension system.
- Mobile or web versions.
