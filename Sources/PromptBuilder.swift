import Foundation

enum PromptBuilder {
    @MainActor
    static func buildMessages(session: ChatSession) -> [OpenAIClient.OpenAIMessage] {
        var messages: [OpenAIClient.OpenAIMessage] = []

        // For custom actions, add the system prompt
        // For preset actions, the instruction is already included in the first user message
        if session.action == .custom {
            messages.append(OpenAIClient.OpenAIMessage(
                role: "system",
                content: session.action.systemPrompt
            ))
        }

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
