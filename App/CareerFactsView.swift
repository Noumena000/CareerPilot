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

    init(store: (any CareerFactsStore)? = nil) {
        self.store = store ?? JSONCareerFactsStore(fileURL: Self.defaultStoreURL())
    }

    func load() async {
        do {
            let profile = try await store.load()
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

        var profile = CareerProfile()
        addVerifiedFact(.firstName, value: firstName, to: &profile)
        addVerifiedFact(.lastName, value: lastName, to: &profile)
        addVerifiedFact(.preferredName, value: preferredName, to: &profile)
        addVerifiedFact(.email, value: email, to: &profile)
        addVerifiedFact(.phone, value: phone, to: &profile)
        addVerifiedFact(.city, value: city, to: &profile)
        addVerifiedFact(.state, value: state, to: &profile)
        addVerifiedFact(.country, value: country, to: &profile)
        addVerifiedFact(.postalCode, value: postalCode, to: &profile)
        addVerifiedFact(.linkedInURL, value: linkedInURL, to: &profile)
        addVerifiedFact(.portfolioURL, value: portfolioURL, to: &profile)
        addVerifiedFact(.websiteURL, value: websiteURL, to: &profile)

        do {
            try await store.save(profile)
            statusMessage = "Saved locally. These facts are now verified for routine autofill."
        } catch {
            statusMessage = "Could not save CareerFacts: \(error.localizedDescription)"
        }
    }

    private func addVerifiedFact(
        _ field: CanonicalCareerField,
        value: String,
        to profile: inout CareerProfile
    ) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile.setFact(
            field,
            value: trimmed,
            source: .userEntered,
            verification: .verified
        )
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
                Text("CareerFacts are the confirmed routine facts CareerPilot may use for deterministic autofill. Saving this page verifies the non-empty values you entered. Sensitive application questions remain manual.")
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
                    Button("Save & Verify") {
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
