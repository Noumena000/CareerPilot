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
    @Published var fillResults: [FillAttemptResult] = []
    @Published var isInspecting = false
    @Published var isFilling = false

    fileprivate weak var webView: WKWebView?
    fileprivate var pageIdentity: BrowserPageIdentity?

    func openAddress() {
        do {
            let url = try ApplicationURLPolicy.resolve(address)
            address = url.absoluteString
            errorMessage = nil
            clearInspection()
            webView?.load(URLRequest(url: url))
        } catch { errorMessage = error.localizedDescription }
    }

    func goBack() { clearInspection(); webView?.goBack() }
    func goForward() { clearInspection(); webView?.goForward() }
    func reload() { clearInspection(); webView?.reload() }

    func inspectPage() async {
        guard let webView, let currentURL else { return }
        guard ApplicationURLPolicy.permitsAutomaticDisclosure(to: currentURL) else {
            errorMessage = "CareerPilot only inspects application fields for autofill on secure HTTPS pages."
            clearInspection(); return
        }
        isInspecting = true
        defer { isInspecting = false }
        let page = BrowserPageIdentity(url: currentURL.absoluteString)
        pageIdentity = page
        fillResults = []
        do {
            let raw = try await webView.evaluateJavaScript(Self.inspectionScript)
            guard let rows = raw as? [[String: Any]] else { throw InspectionError.invalidResult }
            inspectedFields = rows.compactMap { row in
                guard let reference = row["reference"] as? String,
                      let label = row["label"] as? String,
                      let name = row["name"] as? String,
                      let type = row["type"] as? String else { return nil }
                let descriptor = BrowserFieldDescriptor(
                    reference: reference, label: label, name: name, type: type,
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

    func fillSafeProposals() async {
        guard let webView, let currentURL, let pageIdentity, !proposals.isEmpty else { return }
        guard ApplicationURLPolicy.permitsAutomaticDisclosure(to: currentURL) else {
            errorMessage = "CareerPilot will not disclose CareerFacts to an insecure application page."
            return
        }

        isFilling = true
        fillResults = []
        defer { isFilling = false }

        for proposal in proposals {
            guard FillExecutionPolicy.permitsAttempt(proposal, currentPage: pageIdentity, currentURL: currentURL) else {
                fillResults.append(FillAttemptResult(
                    proposalID: proposal.id,
                    canonicalField: proposal.canonicalField,
                    status: .staleTarget,
                    message: "Skipped because the application page changed after inspection."
                ))
                continue
            }

            do {
                let result = try await executeFill(proposal, in: webView)
                fillResults.append(result)
            } catch {
                fillResults.append(FillAttemptResult(
                    proposalID: proposal.id,
                    canonicalField: proposal.canonicalField,
                    status: .writeFailed,
                    message: error.localizedDescription
                ))
            }
        }
    }

    private func executeFill(_ proposal: RoutineFillProposal, in webView: WKWebView) async throws -> FillAttemptResult {
        let descriptor = proposal.inspectedField.descriptor
        let payload: [String: Any] = [
            "reference": proposal.inspectedField.target.reference,
            "expectedName": descriptor.name,
            "expectedID": descriptor.elementID ?? "",
            "expectedType": descriptor.type.lowercased(),
            "value": proposal.proposedValue
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard let json = String(data: data, encoding: .utf8) else { throw FillError.invalidPayload }
        let raw = try await webView.evaluateJavaScript(Self.fillScript(payloadJSON: json))
        guard let row = raw as? [String: Any],
              let statusRaw = row["status"] as? String,
              let status = FillAttemptStatus(rawValue: statusRaw),
              let message = row["message"] as? String else { throw FillError.invalidResult }
        return FillAttemptResult(
            proposalID: proposal.id,
            canonicalField: proposal.canonicalField,
            status: status,
            readbackValue: row["readbackValue"] as? String,
            message: message
        )
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
        fillResults = []
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

    private enum FillError: LocalizedError {
        case invalidPayload
        case invalidResult
        var errorDescription: String? {
            switch self {
            case .invalidPayload: return "CareerPilot could not encode the approved field value."
            case .invalidResult: return "The page returned an unexpected fill result."
            }
        }
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
          reference: ref, label,
          name: el.getAttribute('name') || '',
          type: (el.getAttribute('type') || el.tagName || 'text').toLowerCase(),
          autocomplete: el.getAttribute('autocomplete') || '',
          elementID: el.id || '', placeholder: el.getAttribute('placeholder') || '',
          ariaLabel: el.getAttribute('aria-label') || '', nearbyText: nearby.slice(0, 240),
          currentValue: typeof el.value === 'string' ? el.value : '',
          isDisabled: !!el.disabled, isReadOnly: !!el.readOnly
        };
      });
    })();
    """#

    private static func fillScript(payloadJSON: String) -> String {
        #"""
        (() => {
          const p = \#(payloadJSON);
          const result = (status, message, readbackValue = null) => ({ status, message, readbackValue });
          const el = document.querySelector(`[data-careerpilot-ref="${CSS.escape(p.reference)}"]`);
          if (!el) return result('targetMissing', 'The inspected control no longer exists.');

          const actualName = el.getAttribute('name') || '';
          const actualID = el.id || '';
          const actualType = (el.getAttribute('type') || el.tagName || 'text').toLowerCase();
          if (actualName !== p.expectedName || actualID !== p.expectedID || actualType !== p.expectedType) {
            return result('targetMismatch', 'The control changed after inspection.');
          }
          if (el.disabled || el.readOnly) return result('writeFailed', 'The control became disabled or read-only.');
          if (typeof el.value === 'string' && el.value.trim() !== '') {
            return result('existingValuePreserved', 'A value was entered after inspection, so CareerPilot left it unchanged.', el.value);
          }

          const tag = el.tagName.toLowerCase();
          const allowedInputTypes = new Set(['text', 'email', 'tel', 'url', 'search']);
          try {
            let desired = p.value;
            if (tag === 'select') {
              const option = Array.from(el.options).find(o => o.value === desired)
                || Array.from(el.options).find(o => (o.textContent || '').trim().toLowerCase() === desired.trim().toLowerCase());
              if (!option) return result('unsupportedControl', 'No select option matched the verified CareerFact.');
              desired = option.value;
              el.value = desired;
            } else if (tag === 'textarea') {
              const setter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value')?.set;
              setter ? setter.call(el, desired) : (el.value = desired);
            } else if (tag === 'input' && allowedInputTypes.has(actualType)) {
              const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set;
              setter ? setter.call(el, desired) : (el.value = desired);
            } else {
              return result('unsupportedControl', `CareerPilot does not write this ${actualType} control automatically.`);
            }

            el.dispatchEvent(new Event('input', { bubbles: true }));
            el.dispatchEvent(new Event('change', { bubbles: true }));
            el.dispatchEvent(new Event('blur', { bubbles: false }));
            const readback = typeof el.value === 'string' ? el.value : '';
            if (readback !== desired) return result('readbackFailed', 'The page did not retain the value after the write.', readback);
            return result('verified', 'Value written and verified by readback.', readback);
          } catch (error) {
            return result('writeFailed', error && error.message ? error.message : 'The page rejected the write.');
          }
        })();
        """#
    }
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
        model.webView = webView; model.synchronize(from: webView)
        return webView
    }
    func updateNSView(_ webView: WKWebView, context: Context) { if model.webView !== webView { model.webView = webView } }
    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) { coordinator.stopObserving(); webView.navigationDelegate = nil; webView.uiDelegate = nil }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private weak var model: ApplicationBrowserModel?
        private var observations: [NSKeyValueObservation] = []
        init(model: ApplicationBrowserModel) { self.model = model }
        func observe(_ webView: WKWebView) {
            observations = [
                webView.observe(\.url, options: [.new]) { [weak self] webView, _ in Task { @MainActor in self?.model?.synchronize(from: webView) } },
                webView.observe(\.title, options: [.new]) { [weak self] webView, _ in Task { @MainActor in self?.model?.synchronize(from: webView) } },
                webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in Task { @MainActor in self?.model?.synchronize(from: webView) } },
                webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in Task { @MainActor in self?.model?.synchronize(from: webView) } },
                webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in Task { @MainActor in self?.model?.synchronize(from: webView) } }
            ]
        }
        func stopObserving() { observations.removeAll() }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard ApplicationURLPolicy.permitsNavigation(to: navigationAction.request.url) else {
                Task { @MainActor in self.model?.errorMessage = "CareerPilot blocked navigation to a non-web URL." }; decisionHandler(.cancel); return
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
            browserToolbar; Divider()
            if model.currentURL == nil && !model.isLoading {
                ContentUnavailableView { Label("Open an employer application", systemImage: "safari") } description: {
                    Text("Paste the employer's real application URL above. CareerPilot keeps final submission under your control.")
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    ApplicationWebView(model: model).frame(minWidth: 520)
                    if !model.inspectedFields.isEmpty { inspectionPanel.frame(minWidth: 300, idealWidth: 360, maxWidth: 440) }
                }
            }
        }.navigationTitle(model.pageTitle)
    }

    private var inspectionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safe fill review").font(.headline)
            Text("\(model.inspectedFields.count) controls inspected · \(model.proposals.count) verified routine matches").font(.caption).foregroundStyle(.secondary)
            Divider()
            if model.proposals.isEmpty {
                Text("No empty routine fields matched verified CareerFacts. Existing values and sensitive questions are left alone.").font(.callout).foregroundStyle(.secondary)
            } else {
                List(model.proposals) { proposal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(proposal.inspectedField.descriptor.label.isEmpty ? proposal.canonicalField.rawValue : proposal.inspectedField.descriptor.label).font(.callout).bold()
                        Text(proposal.proposedValue).textSelection(.enabled)
                        Text(proposal.evidence).font(.caption).foregroundStyle(.secondary)
                        if let result = model.fillResults.first(where: { $0.proposalID == proposal.id }) {
                            Label(result.message, systemImage: result.succeeded ? "checkmark.circle" : "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(result.succeeded ? .secondary : .orange)
                        }
                    }.padding(.vertical, 4)
                }
                Button("Fill verified routine fields") { Task { await model.fillSafeProposals() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isFilling)
            }
            Spacer()
            Text("CareerPilot rechecks the target, preserves newly entered values, dispatches normal form events, and verifies every attempted write by readback. Submission remains manual.")
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
                Button("Inspect form") { Task { await model.inspectPage() } }.disabled(model.currentURL == nil || model.isLoading || model.isInspecting || model.isFilling)
                if model.isLoading || model.isInspecting || model.isFilling { ProgressView().controlSize(.small) }
            }
            HStack {
                Label("Employer webpages are untrusted. CareerPilot fills only verified routine facts and never submits automatically.", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary); Spacer()
            }
            if let errorMessage = model.errorMessage {
                HStack { Label(errorMessage, systemImage: "exclamationmark.triangle").font(.callout).foregroundStyle(.red); Spacer(); Button("Dismiss") { model.errorMessage = nil }.buttonStyle(.link) }
            }
        }.padding(12)
    }
}
