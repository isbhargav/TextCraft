import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var isSaved: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: apiKey) { isSaved = false }

                    Button(isSaved ? "Saved ✓" : "Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                }

                HStack(spacing: 6) {
                    Button {
                        testAPIKey()
                    } label: {
                        if isTesting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("Test API Key")
                        }
                    }
                    .disabled(apiKey.isEmpty || isTesting)

                    if let testResult {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(testResult.contains("Success") ? .green : .red)
                    }
                }
            } header: {
                Text("OpenAI API Key")
            } footer: {
                Text("Your API key is stored securely in the macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .frame(width: 420, height: 300)
        .onAppear { loadAPIKey() }
    }

    private func loadAPIKey() {
        if let key = KeychainService.retrieve(key: Constants.keychainAPIKeyAccount) {
            apiKey = key
            isSaved = true
        }
    }

    private func saveAPIKey() {
        let success = KeychainService.save(key: Constants.keychainAPIKeyAccount, value: apiKey)
        if success {
            AppState.shared.apiKey = apiKey
            isSaved = true
            withAnimation { testResult = nil }
        }
    }

    private func testAPIKey() {
        isTesting = true
        testResult = nil

        Task {
            let result = await verifyAPIKey(apiKey)
            isTesting = false
            testResult = result
        }
    }

    private func verifyAPIKey(_ key: String) async -> String {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return "Error: Invalid URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return "Success ✓ Key is valid"
            } else {
                return "Error: Invalid API key"
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
}
