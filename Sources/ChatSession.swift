import Foundation

@MainActor
@Observable
class ChatSession {
    var messages: [ChatMessage] = []
    var isStreaming: Bool = false
    let selectedText: String
    let action: AIAction

    init(selectedText: String, action: AIAction) {
        self.selectedText = selectedText
        self.action = action
    }

    func addUserMessage(_ content: String) {
        messages.append(ChatMessage(role: .user, content: content))
    }

    func addAssistantMessage(_ content: String) {
        messages.append(ChatMessage(role: .assistant, content: content))
    }

    func appendToLastAssistantMessage(_ chunk: String) {
        guard let index = messages.indices.last, messages[index].role == .assistant else { return }
        messages[index].content += chunk
    }

    func removeMessages(from messageID: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageID }) else { return }
        messages.removeSubrange(index...)
    }
}
