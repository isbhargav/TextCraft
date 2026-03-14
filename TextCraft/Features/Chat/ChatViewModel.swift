import SwiftUI

@MainActor
@Observable
class ChatViewModel {
    var session: ChatSession
    var inputText: String = ""
    var error: String?

    private let openAIClient = OpenAIClient()
    private let pastebackService = PastebackService()
    private var streamTask: Task<Void, Never>?

    init(session: ChatSession) {
        self.session = session
    }

    func startInitialRequest() {
        guard session.messages.isEmpty else { return }

        if session.action == .custom {
            return
        }

        session.addUserMessage(session.selectedText)
        streamResponse()
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if session.messages.isEmpty && session.action == .custom {
            session.addUserMessage("Here is the text:\n\n\(session.selectedText)\n\nInstruction: \(text)")
        } else {
            session.addUserMessage(text)
        }

        inputText = ""
        streamResponse()
    }

    func insertResponse(_ text: String) {
        let appState = AppState.shared
        let pid = appState.sourceAppPID
        guard pid != 0 else { return }

        Task {
            await pastebackService.insertText(text, into: pid)
            appState.chatSession = nil
        }
    }

    func cancel() {
        streamTask?.cancel()
        session.isStreaming = false
    }

    private func streamResponse() {
        let appState = AppState.shared
        let apiKey = appState.apiKey
        guard !apiKey.isEmpty else {
            error = "Please set your API key in Settings."
            return
        }

        error = nil
        session.isStreaming = true
        session.addAssistantMessage("")

        let messages = PromptBuilder.buildMessages(session: session)
        let endpoint = appState.endpoint
        let model = appState.model

        streamTask = Task {
            do {
                let stream = await openAIClient.streamChat(messages: messages, apiKey: apiKey, endpoint: endpoint, model: model)
                for try await chunk in stream {
                    session.appendToLastAssistantMessage(chunk)
                }
                session.isStreaming = false
            } catch {
                session.isStreaming = false
                self.error = error.localizedDescription
            }
        }
    }
}
