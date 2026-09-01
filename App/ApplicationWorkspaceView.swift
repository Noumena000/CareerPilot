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

    fileprivate weak var webView: WKWebView?

    func openAddress() {
        do {
            let url = try ApplicationURLPolicy.resolve(address)
            address = url.absoluteString
            errorMessage = nil
            webView?.load(URLRequest(url: url))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    fileprivate func synchronize(from webView: WKWebView) {
        self.webView = webView
        currentURL = webView.url
        if let url = webView.url {
            address = url.absoluteString
        }
        pageTitle = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? webView.title!
            : "Application workspace"
        isLoading = webView.isLoading
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}

struct ApplicationWebView: NSViewRepresentable {
    @ObservedObject var model: ApplicationBrowserModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.setValue(false, forKey: "drawsBackground")

        context.coordinator.observe(webView)
        model.webView = webView
        model.synchronize(from: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if model.webView !== webView {
            model.webView = webView
        }
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stopObserving()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private weak var model: ApplicationBrowserModel?
        private weak var observedWebView: WKWebView?
        private var observations: [NSKeyValueObservation] = []

        init(model: ApplicationBrowserModel) {
            self.model = model
        }

        func observe(_ webView: WKWebView) {
            observedWebView = webView
            observations = [
                webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                    Task { @MainActor in self?.model?.synchronize(from: webView) }
                },
                webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                    Task { @MainActor in self?.model?.synchronize(from: webView) }
                },
                webView.observe(\.isLoading, options: [.new]) { [weak self] webView, _ in
                    Task { @MainActor in self?.model?.synchronize(from: webView) }
                },
                webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                    Task { @MainActor in self?.model?.synchronize(from: webView) }
                },
                webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                    Task { @MainActor in self?.model?.synchronize(from: webView) }
                }
            ]
        }

        func stopObserving() {
            observations.removeAll()
            observedWebView = nil
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard ApplicationURLPolicy.permitsNavigation(to: navigationAction.request.url) else {
                Task { @MainActor in
                    self.model?.errorMessage = "CareerPilot blocked navigation to a non-web URL."
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil,
                  ApplicationURLPolicy.permitsNavigation(to: navigationAction.request.url) else {
                return nil
            }
            webView.load(navigationAction.request)
            return nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            report(error, from: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            report(error, from: webView)
        }

        private func report(_ error: Error, from webView: WKWebView) {
            let nsError = error as NSError
            guard nsError.code != NSURLErrorCancelled else { return }
            Task { @MainActor in
                self.model?.synchronize(from: webView)
                self.model?.errorMessage = "Could not load this application page: \(error.localizedDescription)"
            }
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
                ContentUnavailableView {
                    Label("Open an employer application", systemImage: "safari")
                } description: {
                    Text("Paste the employer's real application URL above. CareerPilot keeps final submission under your control.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ApplicationWebView(model: model)
            }
        }
        .navigationTitle(model.pageTitle)
    }

    private var browserToolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: model.goBack) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!model.canGoBack)
                .help("Back")

                Button(action: model.goForward) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!model.canGoForward)
                .help("Forward")

                Button(action: model.reload) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(model.currentURL == nil)
                .help("Reload")

                TextField("Employer application URL", text: $model.address)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(model.openAddress)

                Button("Open", action: model.openAddress)
                    .keyboardShortcut(.return, modifiers: [.command])

                if model.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            HStack {
                Label("Employer webpages are untrusted content. CareerPilot will not automatically submit this application.", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let errorMessage = model.errorMessage {
                HStack {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.red)
                    Spacer()
                    Button("Dismiss") {
                        model.errorMessage = nil
                    }
                    .buttonStyle(.link)
                }
            }
        }
        .padding(12)
    }
}
