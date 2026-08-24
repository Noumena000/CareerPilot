import SwiftUI

enum OpenClawConnectionState: Equatable {
    case notConfigured
    case checking
    case connected(targets: [String])
    case failed(String)
}

@MainActor
final class OpenClawSettingsModel: ObservableObject {
    @Published var gatewayURL = UserDefaults.standard.string(forKey: "openClawGatewayURL")
        ?? "http://127.0.0.1:18789"
    @Published var token = ""
    @Published private(set) var state: OpenClawConnectionState = .notConfigured

    private let client = OpenClawClient()
    private let tokenAccount = "openclaw-gateway-token"

    init() {
        do {
            token = try KeychainStore.load(account: tokenAccount) ?? ""
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func saveAndCheck() {
        state = .checking

        guard let url = URL(string: gatewayURL), !token.isEmpty else {
            state = .failed("Enter a loopback Gateway URL and token.")
            return
        }

        do {
            try KeychainStore.save(token, account: tokenAccount)
            UserDefaults.standard.set(gatewayURL, forKey: "openClawGatewayURL")
        } catch {
            state = .failed(error.localizedDescription)
            return
        }

        Task {
            do {
                let targets = try await client.checkConnection(baseURL: url, token: token)
                state = .connected(targets: targets)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    var statusText: String {
        switch state {
        case .notConfigured:
            return "Not verified"
        case .checking:
            return "Checking the live Gateway…"
        case .connected(let targets):
            return "Verified: \(targets.joined(separator: ", "))"
        case .failed(let message):
            return "Not connected: \(message)"
        }
    }

    var isChecking: Bool {
        state == .checking
    }
}

struct OpenClawSettingsView: View {
    @StateObject private var model = OpenClawSettingsModel()

    var body: some View {
        Form {
            Section("OpenClaw Gateway") {
                TextField("Gateway URL", text: $model.gatewayURL)
                SecureField("Gateway token", text: $model.token)

                HStack {
                    Button("Save and verify") {
                        model.saveAndCheck()
                    }
                    .disabled(model.isChecking)

                    if model.isChecking {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                Text(model.statusText)
                    .foregroundStyle(statusColor)
            }

            Section("Security boundary") {
                Text("CareerPilot accepts loopback Gateway addresses only. The bearer token is stored in Keychain and is never sent to Safari JavaScript or committed to Git.")
                    .foregroundStyle(.secondary)

                Text("OpenClaw's HTTP token grants operator-level access. Use a dedicated local Gateway and keep it off the public internet.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }

    private var statusColor: Color {
        switch model.state {
        case .connected:
            return .green
        case .failed:
            return .red
        default:
            return .secondary
        }
    }
}
