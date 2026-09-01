import SwiftUI
import CareerPilotCore

private enum SidebarItem: String, Hashable {
    case pipeline
    case drafts
    case answers
    case settings
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .pipeline

    private let steps = [
        "Review qualified jobs in your inbox",
        "Confirm fit and choose a résumé",
        "Open the employer's real application",
        "Review routine field suggestions",
        "Resolve questions, then submit yourself"
    ]

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.pipeline) {
                    Label("Job pipeline", systemImage: "briefcase")
                }
                NavigationLink(value: SidebarItem.drafts) {
                    Label("Application drafts", systemImage: "doc.text")
                }
                NavigationLink(value: SidebarItem.answers) {
                    Label("Answer library", systemImage: "text.book.closed")
                }
                NavigationLink(value: SidebarItem.settings) {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .navigationTitle("CareerPilot")
        } detail: {
            switch selection ?? .pipeline {
            case .settings:
                PrivacySettingsView()
            case .pipeline:
                workflowView
            case .drafts:
                emptyView(
                    title: "Application drafts",
                    message: "Truthful drafts based on confirmed CareerFacts will appear here as the local workspace is built."
                )
            case .answers:
                emptyView(
                    title: "Answer library",
                    message: "Reusable answers will remain local and require your confirmation before use."
                )
            }
        }
    }

    private var workflowView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your job-search workspace")
                .font(.largeTitle.bold())

            Text("CareerPilot's core workflow is local to this Mac and does not require an external agent runtime or browser extension.")
                .foregroundStyle(.secondary)

            GroupBox("Review-first workflow") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Label(step, systemImage: "\(index + 1).circle")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            }

            Spacer()

            Text("CareerPilot never submits an application automatically.")
                .font(.callout.weight(.semibold))
        }
        .padding(32)
    }

    private func emptyView(title: String, message: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: "tray",
            description: Text(message)
        )
    }
}
