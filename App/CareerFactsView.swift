import SwiftUI
import CareerPilotCore

@MainActor
final class CareerFactsViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var preferredName = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var city = ""
    @Published var state = ""
    @Published var country = ""
    @Published var postalCode = ""
    @Published var linkedInURL = ""
    @Published var portfolioURL = ""
    @Published var websiteURL = ""
    @Published var statusMessage: String?
    @Published var isSaving = false

    private let store: any CareerFactsStore
    private var loadedProfile = CareerProfile()

    init(store: (any CareerFactsStore)? = nil) {
        self.store = store ?? JSONCareerFactsStore(fileURL: Self.defaultStoreURL())
    }

    func load() async {
        do {
            let profile = try await store.load()
            loadedProfile = profile
            firstName = profile.fact(for: .firstName)?.value ?? ""
            lastName = profile.fact(for: .lastName)?.value ?? ""
            preferredName = profile.fact(for: .preferredName)?.value ?? ""
            email = profile.fact(for: .email)?.value ?? ""
            phone = profile.fact(for: .phone)?.value ?? ""
            city = profile.fact(for: .city)?.value ?? ""
            state = profile.fact(for: .state)?.value ?? ""
            country = profile.fact(for: .country)?.value ?? ""
            postalCode = profile.fact(for: .postalCode)?.value ?? ""
            linkedInURL = profile.fact(for: .linkedInURL)?.value ?? ""
            portfolioURL = profile.fact(for: .portfolioURL)?.value ?? ""
            websiteURL = profile.fact(for: .websiteURL)?.value ?? ""
            statusMessage = nil
        } catch {
            statusMessage = "Could not load CareerFacts: \(error.localizedDescription)"
        }
    }

    func saveAndVerify() async {
        isSaving = true
        defer { isSaving = false }

        let edits: [CanonicalCareerField: String] = [
            .firstName: firstName,
            .lastName: lastName,
            .preferredName: preferredName,
            .email: email,
            .phone: phone,
            .city: city,
            .state: state,
            .country: country,
            .postalCode: postalCode,
            .linkedInURL: linkedInURL,
            .portfolioURL: portfolioURL,
            .websiteURL: websiteURL
        ]
        let profile = loadedProfile.applyingUserEdits(edits)

        do {
            try await store.save(profile)
            loadedProfile = profile
            statusMessage = "Saved locally. New or changed values you entered are verified; unchanged imported facts keep their prior verification status."
        } catch {
            statusMessage = "Could not save CareerFacts: \(error.localizedDescription)"
        }
    }

    private static func defaultStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return base
            .appendingPathComponent("CareerPilot", isDirectory: true)
            .appendingPathComponent("career-facts.json", isDirectory: false)
    }
}

struct CareerFactsView: View {
    @StateObject private var model = CareerFactsViewModel()

    var body: some View {
        Form {
            Section {
                Text("CareerFacts are the confirmed routine facts CareerPilot may use for deterministic autofill. New or changed values you save here are treated as user-confirmed. Imported values that you leave unchanged keep their existing verification state. Sensitive application questions remain manual.")
                    .foregroundStyle(.secondary)
            }

            Section("Identity") {
                TextField("First name", text: $model.firstName)
                TextField("Last name", text: $model.lastName)
                TextField("Preferred name", text: $model.preferredName)
            }

            Section("Contact") {
                TextField("Email", text: $model.email)
                TextField("Phone", text: $model.phone)
            }

            Section("Location") {
                TextField("City", text: $model.city)
                TextField("State / region", text: $model.state)
                TextField("Country", text: $model.country)
                TextField("Postal code", text: $model.postalCode)
            }

            Section("Professional links") {
                TextField("LinkedIn URL", text: $model.linkedInURL)
                TextField("Portfolio URL", text: $model.portfolioURL)
                TextField("Website URL", text: $model.websiteURL)
            }

            Section {
                HStack {
                    Button("Save & Verify Changes") {
                        Task { await model.saveAndVerify() }
                    }
                    .keyboardShortcut("s", modifiers: [.command])
                    .disabled(model.isSaving)

                    if model.isSaving {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let statusMessage = model.statusMessage {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundStyle(statusMessage.hasPrefix("Could not") ? .red : .secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("CareerFacts")
        .task {
            await model.load()
        }
    }
}
