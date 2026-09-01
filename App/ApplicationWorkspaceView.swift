import SwiftUI
import WebKit
import CareerPilotCore

@MainActor
final class ApplicationBrowserModel: ObservableObject {
    @Published var address = ""
    @Published var currentURL: URL?
    @Published var pageTitle = "Application workspace"
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var errorMessage: String?
    @Published var inspectedFields: [InspectedBrowserField] = []
    @Published var proposals: [RoutineFillProposal] = []
    @Published var isInspecting = false

    fileprivate weak var webView: WKWebView?
    fileprivate var pageIdentity: BrowserPageIdentity?

    func openAddress() {
        do {
            let url = try ApplicationURLPolicy.resolve(address)
            address = url.absoluteString
            errorMessage = nil
            clearInspection()
            webView?.load(URLRequest(url: url))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func goBack() { clearInspection(); webView?.goBack() }
    func goForward() { clearInspection(); webView?.goForward() }
    func reload() { clearInspection(); webView?.reload() }

    func inspectPage() async {
        guard let webView, let currentURL else { return }
        guard ApplicationURLPolicy.permitsAutomaticDisclosure(to: currentURL) else {
            errorMessage = "CareerPilot only inspects application fields for autofill on secure HTTPS pages."
            clearInspection()
            return
        }

        isInspecting = true
        defer { isInspecting = false }

        let page = BrowserPageIdentity(url: currentURL.absoluteString)
        pageIdentity = page

        do {
            let raw = try await webView.evaluateJavaScript(Self.inspectionScript)
            guard let rows = raw as? [[String: Any]] else {
                throw InspectionError.invalidResult
            }

            inspectedFields = rows.compactMap { row in
                guard let reference = row["reference"] as? String,
                      let label = row["label"] as? String,
                      let name = row["name"] as? String,
                      let type = row["type"] as? String else { return nil }

                let descriptor = BrowserFieldDescriptor(
                    reference: reference,
                    label: label,
                    name: name,
                    type: type,
                    autocomplete: row["autocomplete"] as? String,
                    elementID: row["elementID"] as? String,
                    placeholder: row["placeholder"] as? String,
                    ariaLabel: row["ariaLabel"] as? String,
                    nearbyText: row["nearbyText"] as? String
                )
                return InspectedBrowserField(
                    descriptor: descriptor,
                    target: BrowserControlTarget(page: page, reference: reference),
                    currentValue: row["currentValue"] as? String ?? "",
                    isDisabled: row["isDisabled"] as? Bool ?? false,
                    isReadOnly: row["isReadOnly"] as? Bool ?? false
                )
            }

            let profile = try await Self.careerFactsStore().load()
            proposals = RoutineFillPlanner.proposals(for: inspectedFields, profile: profile, pageURL: currentURL)
            errorMessage = nil
        } catch {
            clearInspection()
            errorMessage = "Could not inspect this application form: \(error.localizedDescription)"
        }
    }

    fileprivate func synchronize(from webView: WKWebView) {
        self.webView = webView
        let previousURL = currentURL
        currentURL = webView.url
        if previousURL != currentURL { clearInspection() }
        if let url = webView.url { address = url.absoluteString }
        let title = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        pageTitle = title.isEmpty ? "Application workspace" : title
        isLoading = webView.isLoading
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    fileprivate func clearInspection() {
        inspectedFields = []
        proposals = []
        pageIdentity = nil
    }

    private static func careerFactsStore() -> JSONCareerFactsStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return JSONCareerFactsStore(fileURL: base.appendingPathComponent("CareerPilot", isDirectory: true).appendingPathComponent("career-facts.json"))
    }

    private enum InspectionError: LocalizedError {
        case invalidResult
        var errorDescription: String? { "The page returned an unexpected inspection result." }
    }

    private static let inspectionScript = #"""
    (() => {
      const controls = Array.from(document.querySelectorAll('input, textarea, select'));
      const visibleText = (node) => (node && node.textContent ? node.textContent.trim() : '');
      return controls.map((el, index) => {
        const ref = `cp-${index}`;
        el.setAttribute('data-careerpilot-ref', ref);
        let label = '';
        if (el.labels && el.labels.length) label = Array.from(el.labels).map(visibleText).filter(Boolean).join(' ');
        if (!label && el.id) {
          const explicit = document.querySelector(`label[for="${CSS.escape(el.id)}"]`);
          label = visibleText(explicit);
        }
        const nearby = visibleText(el.closest('label')) || visibleText(el.parentElement);
        return {
          reference: ref,
          label,
          name: el.getAttribute('name') || '',
          type: (el.getAttribute('type') || el.tagName || 'text').toLowerCase(),
          autocomplete: el.getAttribute('autocomplete') || '',
          elementID: el.id || '',
          placeholder: el.getAttribute('placeholder') || '',
          ariaLabel: el.getAttribute('aria-label') || '',
          nearbyText: nearby.slice(0, 240),
          currentValue: typeof el.value === 'string' ? el.value : '',
          isDisabled: !!el.disabled,
          isReadOnly: !!el.readOnly
        };
      });
    })();
    """#
}

struct ApplicationWebView: NSViewRepresentable {
    @ObservedObject var model: ApplicationBrowserModel
    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.observe(webView)
        model.webView = webView
        model.synchronize(from: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) { if model.webView !== webView { model.webView = webView } }
    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stopObserving(); webView.navigationDelegate = nil; webView.uiDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private weak var model: ApplicationBrowserModel?
        private var observations: [NSKeyValueObservation] = []
        init(model: ApplicationBrowserModel) { self.model = model }
        func observe(_ webView: WKWebView) {
            observations = [\.url, \.title, \.isLoading, \.canGoBack, \.canGoForward].map { keyPath in
                webView.observe(keyPath, options: [.new]) { [weak self] webView, _ in
                    Task { @MainActor in self?.model?.synchronize(from: webView) }
                }
            }
        }
        func stopObserving() { observations.removeAll() }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard ApplicationURLPolicy.permitsNavigation(to: navigationAction.request.url) else {
                Task { @MainActor in self.model?.errorMessage = "CareerPilot blocked navigation to a non-web URL." }
                decisionHandler(.cancel); return
            }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard navigationAction.targetFrame == nil, ApplicationURLPolicy.permitsNavigation(to: navigationAction.request.url) else { return nil }
            webView.load(navigationAction.request); return nil
        }
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { Task { @MainActor in self.model?.clearInspection() } }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { report(error, from: webView) }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { report(error, from: webView) }
        private func report(_ error: Error, from webView: WKWebView) {
            let nsError = error as NSError; guard nsError.code != NSURLErrorCancelled else { return }
            Task { @MainActor in self.model?.synchronize(from: webView); self.model?.errorMessage = "Could not load this application page: \(error.localizedDescription)" }
        }
    }
}

struct ApplicationWorkspaceView: View {
    @StateObject private var model = ApplicationBrowserModel()
    var body: some View {
        VStack(spacing: 0) {
            browserToolbar
            Divider()
            if model.currentURL == nil && !model.isLoading {
                ContentUnavailableView { Label("Open an employer application", systemImage: "safari") } description: {
                    Text("Paste the employer's real application URL above. CareerPilot keeps final submission under your control.")
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    ApplicationWebView(model: model).frame(minWidth: 520)
                    if !model.inspectedFields.isEmpty {
                        inspectionPanel.frame(minWidth: 280, idealWidth: 340, maxWidth: 420)
                    }
                }
            }
        }.navigationTitle(model.pageTitle)
    }

    private var inspectionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safe fill review").font(.headline)
            Text("\(model.inspectedFields.count) controls inspected · \(model.proposals.count) verified routine matches")
                .font(.caption).foregroundStyle(.secondary)
            Divider()
            if model.proposals.isEmpty {
                Text("No empty routine fields matched verified CareerFacts. Existing values and sensitive questions are left alone.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                List(model.proposals) { proposal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(proposal.inspectedField.descriptor.label.isEmpty ? proposal.canonicalField.rawValue : proposal.inspectedField.descriptor.label)
                            .font(.callout).bold()
                        Text(proposal.proposedValue).textSelection(.enabled)
                        Text(proposal.evidence).font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 4)
                }
            }
            Spacer()
            Text("Review only: this stage does not write to the webpage or submit anything.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(12)
    }

    private var browserToolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: model.goBack) { Image(systemName: "chevron.left") }.disabled(!model.canGoBack).help("Back")
                Button(action: model.goForward) { Image(systemName: "chevron.right") }.disabled(!model.canGoForward).help("Forward")
                Button(action: model.reload) { Image(systemName: "arrow.clockwise") }.disabled(model.currentURL == nil).help("Reload")
                TextField("Employer application URL", text: $model.address).textFieldStyle(.roundedBorder).onSubmit(model.openAddress)
                Button("Open", action: model.openAddress).keyboardShortcut(.return, modifiers: [.command])
                Button("Inspect form") { Task { await model.inspectPage() } }
                    .disabled(model.currentURL == nil || model.isLoading || model.isInspecting)
                if model.isLoading || model.isInspecting { ProgressView().controlSize(.small) }
            }
            HStack {
                Label("Employer webpages are untrusted. Inspection is read-only and CareerPilot never submits automatically.", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            if let errorMessage = model.errorMessage {
                HStack {
                    Label(errorMessage, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.red)
                    Spacer(); Button("Dismiss") { model.errorMessage = nil }.buttonStyle(.link)
                }
            }
        }.padding(12)
    }
}
