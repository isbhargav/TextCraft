import Foundation

enum AIAction: String, CaseIterable, Identifiable {
    case fixGrammar = "Fix Grammar"
    case rewrite = "Rewrite"
    case summarize = "Summarize"
    case makeShorter = "Make Shorter"
    case makeLonger = "Make Longer"
    case explain = "Explain"
    case custom = "Custom Prompt"

    var id: String { rawValue }

    var systemPrompt: String {
        if let custom = UserDefaults.standard.string(forKey: promptKey), !custom.isEmpty {
            return custom
        }
        return defaultPrompt
    }

    var defaultPrompt: String {
        switch self {
        case .fixGrammar:
            return "Fix the grammar and spelling in the following text. Return only the corrected text without explanations."
        case .rewrite:
            return "Rewrite the following text to be clearer and more professional. Return only the rewritten text."
        case .summarize:
            return "Summarize the following text concisely. Return only the summary."
        case .makeShorter:
            return "Make the following text shorter while preserving its meaning. Return only the shortened text."
        case .makeLonger:
            return "Expand the following text with more detail while keeping the same tone. Return only the expanded text."
        case .explain:
            return "Explain the following text in simple terms."
        case .custom:
            return "You are a helpful writing assistant."
        }
    }

    var promptKey: String {
        "prompt.\(rawValue)"
    }

    var icon: String {
        switch self {
        case .fixGrammar: return "textformat.abc"
        case .rewrite: return "arrow.triangle.2.circlepath"
        case .summarize: return "text.badge.minus"
        case .makeShorter: return "arrow.down.right.and.arrow.up.left"
        case .makeLonger: return "arrow.up.left.and.arrow.down.right"
        case .explain: return "lightbulb"
        case .custom: return "text.cursor"
        }
    }
}
