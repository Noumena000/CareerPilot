import Foundation

public enum FieldMatchConfidence: String, Codable, Sendable {
    case high
    case exact
}

public struct CareerFieldMatch: Codable, Equatable, Sendable {
    public let field: BrowserFieldDescriptor
    public let canonicalField: CanonicalCareerField
    public let value: String
    public let confidence: FieldMatchConfidence
    public let evidence: String

    public init(
        field: BrowserFieldDescriptor,
        canonicalField: CanonicalCareerField,
        value: String,
        confidence: FieldMatchConfidence,
        evidence: String
    ) {
        self.field = field
        self.canonicalField = canonicalField
        self.value = value
        self.confidence = confidence
        self.evidence = evidence
    }
}

public enum CareerFieldMatcher {
    private struct Candidate {
        let field: CanonicalCareerField
        let score: Int
        let evidence: String
    }

    private static let autocompleteMap: [String: CanonicalCareerField] = [
        "given-name": .firstName,
        "family-name": .lastName,
        "name": .fullName,
        "nickname": .preferredName,
        "email": .email,
        "tel": .phone,
        "address-level2": .city,
        "address-level1": .state,
        "country": .country,
        "country-name": .country,
        "postal-code": .postalCode
    ]

    private static let aliases: [CanonicalCareerField: [String]] = [
        .firstName: ["first name", "firstname", "given name", "givenname"],
        .lastName: ["last name", "lastname", "family name", "familyname", "surname"],
        .fullName: ["full name", "fullname", "legal name"],
        .preferredName: ["preferred name", "preferredname", "nickname"],
        .email: ["email", "email address", "emailaddress", "e mail"],
        .phone: ["phone", "phone number", "phonenumber", "telephone", "mobile", "mobile number"],
        .city: ["city", "town", "locality"],
        .state: ["state", "province", "region", "state province"],
        .country: ["country", "country name"],
        .postalCode: ["postal code", "postalcode", "zip", "zip code", "zipcode"],
        .linkedInURL: ["linkedin", "linkedin url", "linkedin profile", "linkedin profile url", "linkedinprofile"],
        .portfolioURL: ["portfolio", "portfolio url", "portfolio website", "portfolio website url", "portfolio site"],
        .websiteURL: ["website", "website url", "personal website", "personal website url", "personal site", "homepage"]
    ]

    public static func match(
        _ descriptor: BrowserFieldDescriptor,
        against profile: CareerProfile
    ) -> CareerFieldMatch? {
        guard FieldPolicy.classify(descriptor) == .routine else { return nil }

        let candidates = candidates(for: descriptor)
            .sorted {
                if $0.score == $1.score { return $0.field.rawValue < $1.field.rawValue }
                return $0.score > $1.score
            }

        guard let best = candidates.first, best.score >= 80 else { return nil }

        if candidates.count > 1,
           candidates[1].score == best.score,
           candidates[1].field != best.field {
            return nil
        }

        guard let value = profile.verifiedValue(for: best.field) else { return nil }

        return CareerFieldMatch(
            field: descriptor,
            canonicalField: best.field,
            value: value,
            confidence: best.score >= 100 ? .exact : .high,
            evidence: best.evidence
        )
    }

    private static func candidates(for descriptor: BrowserFieldDescriptor) -> [Candidate] {
        var result: [Candidate] = []

        if let autocomplete = normalizedAutocomplete(descriptor.autocomplete),
           let field = autocompleteMap[autocomplete] {
            result.append(Candidate(field: field, score: 100, evidence: "autocomplete=\(autocomplete)"))
        }

        let type = descriptor.type.lowercased()
        if type == "email" {
            result.append(Candidate(field: .email, score: 100, evidence: "type=email"))
        } else if type == "tel" {
            result.append(Candidate(field: .phone, score: 100, evidence: "type=tel"))
        }

        let signals: [(String, Int, String)] = [
            (descriptor.label, 95, "label"),
            (descriptor.ariaLabel ?? "", 92, "aria-label"),
            (descriptor.name, 90, "name"),
            (descriptor.elementID ?? "", 90, "id"),
            (descriptor.placeholder ?? "", 85, "placeholder"),
            (descriptor.nearbyText ?? "", 70, "nearby-text")
        ]

        for (rawSignal, score, source) in signals {
            guard !rawSignal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            let normalizedSignal = normalize(rawSignal)

            for field in CanonicalCareerField.allCases {
                guard let fieldAliases = aliases[field] else { continue }
                if fieldAliases.contains(where: { aliasMatches(normalizedSignal, alias: normalize($0)) }) {
                    result.append(Candidate(field: field, score: score, evidence: "\(source)=\(rawSignal)"))
                }
            }
        }

        return bestCandidatePerField(result)
    }

    private static func bestCandidatePerField(_ candidates: [Candidate]) -> [Candidate] {
        var best: [CanonicalCareerField: Candidate] = [:]
        for candidate in candidates {
            if let existing = best[candidate.field], existing.score >= candidate.score {
                continue
            }
            best[candidate.field] = candidate
        }
        return Array(best.values)
    }

    private static func normalizedAutocomplete(_ value: String?) -> String? {
        guard let value else { return nil }
        let tokens = value.lowercased().split(whereSeparator: { $0.isWhitespace }).map(String.init)
        return tokens.last
    }

    private static func normalize(_ value: String) -> String {
        let expanded = value
            .replacingOccurrences(of: "([a-z0-9])([A-Z])", with: "$1 $2", options: .regularExpression)
            .lowercased()

        return expanded
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func aliasMatches(_ signal: String, alias: String) -> Bool {
        signal == alias || signal.replacingOccurrences(of: " ", with: "") == alias.replacingOccurrences(of: " ", with: "")
    }
}
