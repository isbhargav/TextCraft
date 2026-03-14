import Foundation

actor OpenAIClient {
    struct OpenAIMessage: Codable, Sendable {
        let role: String
        let content: String
    }

    private struct ChatRequest: Codable {
        let model: String
        let messages: [OpenAIMessage]
        let stream: Bool
    }

    private struct StreamResponse: Codable {
        struct Choice: Codable {
            struct Delta: Codable {
                let content: String?
            }
            let delta: Delta
        }
        let choices: [Choice]
    }

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config)
    }

    func streamChat(messages: [OpenAIMessage], apiKey: String, endpoint: String, model: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: endpoint) else {
                        continuation.finish(throwing: OpenAIError.invalidEndpoint)
                        return
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let body = ChatRequest(
                        model: model,
                        messages: messages,
                        stream: true
                    )
                    request.httpBody = try JSONEncoder().encode(body)

                    let (bytes, response) = try await self.session.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: OpenAIError.invalidResponse)
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: OpenAIError.httpError(httpResponse.statusCode))
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let data = String(line.dropFirst(6))

                        if data == "[DONE]" {
                            break
                        }

                        guard let jsonData = data.data(using: .utf8),
                              let streamResponse = try? JSONDecoder().decode(StreamResponse.self, from: jsonData),
                              let content = streamResponse.choices.first?.delta.content else {
                            continue
                        }

                        continuation.yield(content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    enum OpenAIError: LocalizedError {
        case invalidResponse
        case invalidEndpoint
        case httpError(Int)
        case noAPIKey

        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid response from server"
            case .invalidEndpoint: return "Invalid endpoint URL"
            case .httpError(let code): return "Server returned HTTP \(code)"
            case .noAPIKey: return "No API key configured"
            }
        }
    }
}
