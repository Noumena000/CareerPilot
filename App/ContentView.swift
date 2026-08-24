import SwiftUI
import CareerPilotCore

struct ContentView: View {
    private let steps = [
        "Capture a job from Safari",
        "Review fit and evidence",
        "Prepare truthful materials",
        "Approve individual field proposals",
        "Verify writes, then submit yourself"
    ]

    var body: some View {
        NavigationSplitView {
            List {
                Label("Job pipeline", systemImage: "briefcase")
                Label("Application drafts", systemImage: "doc.text")
                Label("Answer library", systemImage: "text.book.closed")
                Label("Settings", systemImage: "gearshape")
            }
            .navigationTitle("CareerPilot")
        } detail: {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your job-search workspace")
                    .font(.largeTitle.bold())

                Text("Safari and OpenClaw are not connected yet. The app will show a connection only after a live handshake succeeds.")
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
    }
}
