import SwiftUI
import CareerPilotCore

struct ResumeLibraryView: View {
    @StateObject private var store = ResumeLibraryStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Résumé library").font(.largeTitle.bold())
                    Text("CareerPilot stores imported résumés privately on this Mac and uses only the résumé you explicitly select.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Import résumé") { store.importResume() }
                    .buttonStyle(.borderedProminent)
            }

            if store.library.resumes.isEmpty {
                ContentUnavailableView(
                    "No résumés yet",
                    systemImage: "doc.badge.plus",
                    description: Text("Import a PDF, DOC, or DOCX résumé. The imported copy is stored inside CareerPilot's sandbox.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(store.library.resumes) { resume in
                    HStack(spacing: 12) {
                        Image(systemName: store.library.selectedResumeID == resume.id ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(store.library.selectedResumeID == resume.id ? Color.accentColor : Color.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resume.displayName).font(.headline)
                            Text(resume.originalFilename).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.library.selectedResumeID == resume.id {
                            Text("Selected").font(.caption).foregroundStyle(.secondary)
                        } else {
                            Button("Use this résumé") { store.select(resume.id) }
                                .buttonStyle(.bordered)
                        }
                        Button(role: .destructive) { store.remove(resume.id) } label: { Image(systemName: "trash") }
                            .help("Remove résumé from CareerPilot")
                    }
                    .padding(.vertical, 5)
                }
            }

            if let errorMessage = store.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
        .task { store.load() }
    }
}
