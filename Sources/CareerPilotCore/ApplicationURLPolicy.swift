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

        let explicitScheme = detectedScheme(in: trimmed)
        if let explicitScheme,
           explicitScheme != "https",
           explicitScheme != "http" {
            throw ApplicationURLPolicyError.unsupportedScheme(explicitScheme)
        }

        let candidate = explicitScheme == nil ? "https://\(trimmed)" : trimmed

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host,
              !host.isEmpty else {
            throw ApplicationURLPolicyError.invalid
        }

        return url
    }

    public static func permitsNavigation(to url: URL?) -> Bool {
        guard let scheme = url?.scheme?.lowercased() else { return false }
        return scheme == "https" || scheme == "http" || scheme == "about"
    }

    public static func permitsAutomaticDisclosure(to url: URL?) -> Bool {
        url?.scheme?.lowercased() == "https" && !(url?.host?.isEmpty ?? true)
    }

    private static func detectedScheme(in value: String) -> String? {
        guard let colonIndex = value.firstIndex(of: ":") else { return nil }
        let candidate = String(value[..<colonIndex])
        guard !candidate.isEmpty,
              candidate.first?.isLetter == true,
              candidate.dropFirst().allSatisfy({ $0.isLetter || $0.isNumber || $0 == "+" || $0 == "-" || $0 == "." }) else {
            return nil
        }
        return candidate.lowercased()
    }
}
