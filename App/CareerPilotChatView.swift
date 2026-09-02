import SwiftUI
import CareerPilotCore

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class CareerPilotChatModel: ObservableObject {
    @Published var prompt = ""
    @Published private(set) var messages: [(role: String, text: String)] = []
    @Published private(set) var isWorking = false
    @Published private(set) var status: String?

    let captureStore = PageCaptureStore()

    func load() { captureStore.load() }

    func ask() async {
        let question = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        prompt = ""
        messages.append(("You", question))
        isWorking = true
        defer { isWorking = false }

        guard let capture = captureStore.latestCapture else {
            messages.append(("CareerPilot", "Capture an application page first. I need the page questions and job context before I can draft answers."))
            return
        }

        let context = """
        You are CareerPilot, a review-first job application assistant. Use only the supplied page context. Never invent qualifications or answer legal, demographic, identity, sponsorship, criminal-history, drug-screening, compensation, CAPTCHA, or submission questions on the user's behalf. For those, explain why review is required and suggest what evidence the user should consider. For ordinary experience questions, draft a concise answer grounded in the context and clearly label it as a draft.

        Page title: \(capture.title)
        Page URL: \(capture.url)
        Page text:
        \(capture.text)

        User request: \(question)
        """

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            guard case .available = availability else {
                status = "Apple Foundation Models is unavailable on this Mac or in this region."
                messages.append(("CareerPilot", status ?? "The on-device model is unavailable."))
                return
            }
            do {
                let session = LanguageModelSession(instructions: "Answer conservatively, cite the supplied page context, and keep final decisions with the user.")
                let response = try await session.respond(to: context)
                messages.append(("CareerPilot", response.content))
                status = "Draft generated on-device. Review it before using it."
            } catch {
                status = "The on-device model could not generate a draft: \(error.localizedDescription)"
                messages.append(("CareerPilot", status ?? "Generation failed."))
            }
        } else {
            status = "Apple Foundation Models requires macOS 26 or later."
            messages.append(("CareerPilot", status ?? "The on-device model is unavailable."))
        }
        #else
        status = "This build does not include Apple Foundation Models."
        messages.append(("CareerPilot", status ?? "The on-device model is unavailable."))
        #endif
    }
}

struct CareerPilotChatView: View {
    @StateObject private var model = CareerPilotChatModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CareerPilot chat").font(.largeTitle.bold())
            Text("Ask about the captured application or request a draft grounded in your saved context. Drafts are never submitted automatically.")
                .foregroundStyle(.secondary)

            if let capture = model.captureStore.latestCapture {
                Label("Context: \(capture.title.isEmpty ? capture.url : capture.title)", systemImage: "doc.text.magnifyingglass")
                    .font(.callout)
                Text("\(capture.fields.count) fields captured · \(capture.text.count) characters")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ContentUnavailableView("No page context yet", systemImage: "text.bubble", description: Text("Use Capture page in the Safari CareerPilot menu, then return here."))
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(model.messages.enumerated()), id: \.offset) { _, message in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(message.role).font(.caption.bold()).foregroundStyle(.secondary)
                            Text(message.text).textSelection(.enabled)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .frame(maxHeight: .infinity)

            HStack(alignment: .bottom) {
                TextField("Ask about this application…", text: $model.prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Button("Ask") { Task { await model.ask() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isWorking || model.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let status = model.status {
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .navigationTitle("CareerPilot chat")
        .task { model.load() }
    }
}
