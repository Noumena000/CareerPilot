import Foundation
import CareerPilotCore

@MainActor
final class PageCaptureStore: ObservableObject {
    @Published private(set) var latestCapture: BrowserPageCapture?
    @Published private(set) var loadError: String?

    func load() {
        guard let url = Self.captureURL() else {
            loadError = "CareerPilot's shared capture container is unavailable."
            return
        }
        do {
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            latestCapture = try decoder.decode(BrowserPageCapture.self, from: data)
            loadError = nil
        } catch {
            loadError = "Could not load the latest captured page: \(error.localizedDescription)"
        }
    }

    static func captureURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.noumena.CareerPilot")?
            .appendingPathComponent("latest-page-capture.json", isDirectory: false)
    }
}
