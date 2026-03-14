import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var endpoint: String = ""
    @State private var model: String = ""
    @State private var isSaved: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    @State private var curlCommand: String?
    @State private var hasAccessibility: Bool = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Endpoint")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("https://api.openai.com/v1/chat/completions", text: $endpoint)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                        .onChange(of: endpoint) { isSaved = false }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("gpt-4o-mini", text: $model)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                        .onChange(of: model) { isSaved = false }
                }
            } header: {
                Text("Provider")
            } footer: {
                Text("Any OpenAI-compatible endpoint — OpenAI, AWS Bedrock, Azure, Ollama, etc.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                        .onChange(of: apiKey) { isSaved = false }
                }
            } header: {
                Text("API Key")
            } footer: {
                Text("Stored securely in the macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Button(isSaved ? "Saved ✓" : "Save") {
                        save()
                    }
                    .disabled(apiKey.isEmpty || endpoint.isEmpty || model.isEmpty)

                    Button {
                        testConnection()
                    } label: {
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Test Connection")
                        }
                    }
                    .disabled(apiKey.isEmpty || endpoint.isEmpty || model.isEmpty || isTesting)

                    if let testResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testResult.contains("Success") ? .green : .red)
                            .lineLimit(2)
                    }
                }

                if let curlCommand {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Equivalent curl")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(curlCommand, forType: .string)
                            }
                            .font(.caption)
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.accentColor)
                        }
                        Text(curlCommand)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility")
                            .font(.body)
                        Text(hasAccessibility ? "Permission granted" : "Required to read selected text")
                            .font(.caption)
                            .foregroundStyle(hasAccessibility ? .green : .secondary)
                    }
                    Spacer()
                    if hasAccessibility {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Grant Access") {
                            openAccessibilitySettings()
                        }
                    }
                }
            } header: {
                Text("Permissions")
            } footer: {
                if !hasAccessibility {
                    Text("TextCraft needs Accessibility permission to read selected text from other apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    Text("Hotkey")
                    Spacer()
                    Text("⌘⇧X")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Shortcut")
            } footer: {
                Text("Select text in any app and press the hotkey to activate TextCraft.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 580)
        .onAppear {
            load()
            checkAccessibility()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkAccessibility()
        }
    }

    private func load() {
        let state = AppState.shared
        apiKey = KeychainService.retrieve(key: Constants.keychainAPIKeyAccount) ?? ""
        endpoint = state.endpoint
        model = state.model
        isSaved = !apiKey.isEmpty
    }

    private func save() {
        let _ = KeychainService.save(key: Constants.keychainAPIKeyAccount, value: apiKey)
        UserDefaults.standard.set(endpoint, forKey: "endpoint")
        UserDefaults.standard.set(model, forKey: "model")

        let state = AppState.shared
        state.apiKey = apiKey
        state.endpoint = endpoint
        state.model = model

        isSaved = true
        withAnimation { testResult = nil }
    }

    private func checkAccessibility() {
        hasAccessibility = AXIsProcessTrusted()
    }

    private func openAccessibilitySettings() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func testConnection() {
        isTesting = true
        testResult = nil

        let bodyJSON = """
        {"model":"\(model)","messages":[{"role":"user","content":"Hi"}]}
        """

        curlCommand = """
        curl '\(endpoint)' \\
          -H 'Authorization: Bearer \(String(apiKey.prefix(8)))...' \\
          -H 'Content-Type: application/json' \\
          -d '\(bodyJSON)'
        """

        Task {
            let result = await verifyConnection()
            isTesting = false
            testResult = result
        }
    }

    private func verifyConnection() async -> String {
        guard let url = URL(string: endpoint) else {
            return "Error: Invalid endpoint URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "Hi"]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return "Success ✓ Connected"
            } else if let httpResponse = response as? HTTPURLResponse {
                let responseBody = String(data: data, encoding: .utf8) ?? ""
                return "Error: HTTP \(httpResponse.statusCode) — \(responseBody.prefix(200))"
            }
            return "Error: Invalid response"
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
