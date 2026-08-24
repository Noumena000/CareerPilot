import Foundation

public enum GatewayEndpointError: Error, Equatable {
    case invalidURL
    case unsupportedScheme
    case nonLoopbackHost
}

public enum GatewayEndpointPolicy {
    public static func validate(_ url: URL) throws {
        guard let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased() else {
            throw GatewayEndpointError.invalidURL
        }

        guard scheme == "http" || scheme == "https" else {
            throw GatewayEndpointError.unsupportedScheme
        }

        let loopbackHosts: Set<String> = ["localhost", "127.0.0.1", "::1"]
        guard loopbackHosts.contains(host) else {
            throw GatewayEndpointError.nonLoopbackHost
        }
    }

    public static func modelsURL(from baseURL: URL) throws -> URL {
        try validate(baseURL)
        return baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("models")
    }
}
