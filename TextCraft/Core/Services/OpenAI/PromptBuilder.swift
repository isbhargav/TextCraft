import Foundation

enum PromptBuilder {
    @MainActor
    static func buildMessages(session: ChatSession) -> [OpenAIClient.OpenAIMessage] {
        var messages: [OpenAIClient.OpenAIMessage] = []

        // System prompt based on action
        messages.append(OpenAIClient.OpenAIMessage(
            role: "system",
            content: session.action.systemPrompt
        ))

        // Conversation history: user messages and assistant responses
        for message in session.messages {
            messages.append(OpenAIClient.OpenAIMessage(
                role: message.role == .user ? "user" : "assistant",
                content: message.content
            ))
        }

        return messages
    }
}
