import Foundation
import SafariServices
import os.log

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
                "type": "PONG",
                "openClaw": "notConfigured"
            ])
        case "PAGE_CAPTURE":
            // Page content is intentionally not persisted during the bridge milestone.
            complete(context, response: [
                "ok": true,
                "type": "CAPTURE_RECEIVED",
                "openClaw": "notConfigured"
            ])
        default:
            complete(context, response: [
                "ok": false,
                "error": "Unsupported message type"
            ])
        }
    }

    private func complete(_ context: NSExtensionContext, response: [String: Any]) {
        let item = NSExtensionItem()
        item.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [item])
    }
}
