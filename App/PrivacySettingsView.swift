import SwiftUI

struct PrivacySettingsView: View {
    var body: some View {
        Form {
            Section("Local-first workspace") {
                Text("CareerPilot is designed to keep candidate facts, résumés, reusable answers, and application history on this Mac.")
                    .foregroundStyle(.secondary)

                Text("No external AI service is required for normal app operation. Sending career or application data to a cloud service requires a separate, explicit authorization.")
                    .foregroundStyle(.secondary)
            }

            Section("Application safety") {
                Text("Routine fields may be proposed only from confirmed CareerFacts. Sensitive, legal, ambiguous, identity, demographic, and unsupported questions stay with you.")
                    .foregroundStyle(.secondary)

                Text("CareerPilot never submits an application automatically.")
                    .fontWeight(.semibold)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
