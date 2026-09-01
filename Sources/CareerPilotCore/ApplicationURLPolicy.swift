import Foundation

public enum ApplicationURLPolicyError: Error, Equatable, LocalizedError, Sendable {
    case empty
    case invalid
    case unsupportedScheme(String?)

    public var errorDescription: String? {
        switch self {
        case .empty:
            return "Enter an employer application URL."
        case .invalid:
            return "That does not look like a valid web address."
        case .unsupportedScheme(let scheme):
            if let scheme, !scheme.isEmpty {
                return "CareerPilot only opens HTTP or HTTPS application pages, not \(scheme) URLs."
            }
            return "CareerPilot only opens HTTP or HTTPS application pages."
        }
    }
}

public enum ApplicationURLPolicy {
    public static func resolve(_ rawValue: String) throws -> URL {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ApplicationURLPolicyError.empty }

        let candidate: String
        if trimmed.contains("://") {
            candidate = trimmed
        } else {
            candidate = "https://\(trimmed)"
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              let host = url.host,
              !host.isEmpty else {
            throw ApplicationURLPolicyError.invalid
        }

        guard scheme == "https" || scheme == "http" else {
            throw ApplicationURLPolicyError.unsupportedScheme(url.scheme)
        }

        return url
    }

    public static func permitsNavigation(to url: URL?) -> Bool {
        guard let scheme = url?.scheme?.lowercased() else { return false }
        return scheme == "https" || scheme == "http" || scheme == "about"
    }
}
