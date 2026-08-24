import Foundation
import CareerPilotCore

struct OpenClawModel: Decodable, Equatable {
    let id: String
}

private struct OpenClawModelList: Decodable {
    let data: [OpenClawModel]
}

enum OpenClawClientError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)
    case noAgentTargets

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "OpenClaw returned an invalid response."
        case .httpStatus(let status):
            return "OpenClaw returned HTTP \(status)."
        case .noAgentTargets:
            return "The Gateway responded, but no OpenClaw agent targets were available."
        }
    }
}

actor OpenClawClient {
    func checkConnection(baseURL: URL, token: String) async throws -> [String] {
        let modelsURL = try GatewayEndpointPolicy.modelsURL(from: baseURL)
        var request = URLRequest(url: modelsURL)
        request.timeoutInterval = 10
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OpenClawClientError.invalidResponse
        }

        guard http.statusCode == 200 else {
            throw OpenClawClientError.httpStatus(http.statusCode)
        }

        let models = try JSONDecoder().decode(OpenClawModelList.self, from: data)
        let targets = models.data
            .map(\.id)
            .filter { $0 == "openclaw" || $0.hasPrefix("openclaw/") }

        guard !targets.isEmpty else {
            throw OpenClawClientError.noAgentTargets
        }

        return targets
    }
}
