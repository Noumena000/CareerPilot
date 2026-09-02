import Foundation
import SafariServices
import os.log
#if canImport(FoundationModels)
import FoundationModels
#endif

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let logger = Logger(subsystem: "com.noumena.CareerPilot", category: "SafariBridge")

    func beginRequest(with context: NSExtensionContext) {
        guard
            let item = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
            let type = message["type"] as? String
        else {
            complete(context, response: [
                "ok": false,
                "error": "Malformed native message"
            ])
            return
        }

        logger.info("Received Safari message type: \(type, privacy: .public)")

        switch type {
        case "PING":
            complete(context, response: [
                "ok": true,
                "type": "PONG"
            ])
        case "PAGE_CAPTURE":
            guard let capture = message["capture"] as? [String: Any], let data = Self.captureData(capture) else {
                complete(context, response: ["ok": false, "error": "Invalid page capture"])
                return
            }
            complete(context, response: Self.storeCapture(data) ? ["ok": true, "type": "CAPTURE_STORED"] : ["ok": false, "error": "Could not store page capture"])
        case "CHAT_REQUEST":
            guard let capture = message["capture"] as? [String: Any], let prompt = message["prompt"] as? String, let data = Self.captureData(capture) else {
                complete(context, response: ["ok": false, "error": "Invalid chat request"])
                return
            }
            _ = Self.storeCapture(data)
            Task { await self.answer(prompt: prompt, capture: capture, context: context) }
        default:
            complete(context, response: [
                "ok": false,
                "error": "Unsupported message type"
            ])
        }
    }

    private static func captureData(_ capture: [String: Any]) -> Data? {
        guard JSONSerialization.isValidJSONObject(capture) else { return nil }
        return try? JSONSerialization.data(withJSONObject: capture)
    }

    private static func storeCapture(_ data: Data) -> Bool {
        guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.noumena.CareerPilot") else { return false }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent("latest-page-capture.json"), options: .atomic)
            return true
        } catch { return false }
    }

    private func answer(prompt: String, capture: [String: Any], context: NSExtensionContext) async {
        let pageText = (capture["text"] as? String ?? "").prefix(24_000)
        let title = capture["title"] as? String ?? "Untitled application"
        let request = """
        You are CareerPilot, a review-first job application assistant. Draft only from the supplied page context. Never invent qualifications. Never answer legal, demographic, identity, sponsorship, criminal-history, drug-screening, compensation, CAPTCHA, or submission questions; explain that the user must review those personally. For ordinary experience questions, write a concise draft and label it as a draft.

        Application: \(title)
        Page context:
        \(pageText)

        User request: \(prompt)
        """

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            guard case .available = SystemLanguageModel.default.availability else {
                complete(context, response: ["ok": false, "error": "Apple Foundation Models is unavailable on this Mac or in this region."])
                return
            }
            do {
                let session = LanguageModelSession(instructions: "Keep the user in control. Return only a helpful draft or review explanation.")
                let response = try await session.respond(to: request)
                complete(context, response: ["ok": true, "response": response.content])
            } catch {
                complete(context, response: ["ok": false, "error": "On-device drafting failed."])
            }
        } else {
            complete(context, response: ["ok": false, "error": "Apple Foundation Models requires macOS 26 or later."])
        }
        #else
        complete(context, response: ["ok": false, "error": "This build does not include Apple Foundation Models."])
        #endif
    }

    private func complete(_ context: NSExtensionContext, response: [String: Any]) {
        let item = NSExtensionItem()
        item.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [item])
    }
}
