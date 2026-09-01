import Foundation

public enum CanonicalCareerField: String, Codable, CaseIterable, Sendable {
    case firstName = "first_name"
    case lastName = "last_name"
    case fullName = "full_name"
    case preferredName = "preferred_name"
    case email
    case phone
    case city
    case state
    case country
    case postalCode = "postal_code"
    case linkedInURL = "linkedin_url"
    case portfolioURL = "portfolio_url"
    case websiteURL = "website_url"
}

public enum CareerFactSource: String, Codable, Sendable {
    case userEntered
    case imported
}

public enum CareerFactVerification: String, Codable, Sendable {
    case unverified
    case verified
}

public struct CareerFact: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let field: CanonicalCareerField
    public var value: String
    public var source: CareerFactSource
    public var verification: CareerFactVerification
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        field: CanonicalCareerField,
        value: String,
        source: CareerFactSource = .userEntered,
        verification: CareerFactVerification = .unverified,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.field = field
        self.value = value
        self.source = source
        self.verification = verification
        self.updatedAt = updatedAt
    }

    public var normalizedValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var isUsableForAutomaticFill: Bool {
        verification == .verified && !normalizedValue.isEmpty
    }
}

public struct CareerProfile: Codable, Equatable, Sendable {
    public var facts: [CareerFact]

    public init(facts: [CareerFact] = []) {
        self.facts = facts
    }

    public func fact(for field: CanonicalCareerField) -> CareerFact? {
        facts.last { $0.field == field }
    }

    public func verifiedValue(for field: CanonicalCareerField) -> String? {
        if let fact = fact(for: field), fact.isUsableForAutomaticFill {
            return fact.normalizedValue
        }

        if field == .fullName,
           let firstName = verifiedValue(for: .firstName),
           let lastName = verifiedValue(for: .lastName) {
            return "\(firstName) \(lastName)"
        }

        return nil
    }

    public mutating func setFact(
        _ field: CanonicalCareerField,
        value: String,
        source: CareerFactSource = .userEntered,
        verification: CareerFactVerification = .unverified,
        updatedAt: Date = Date()
    ) {
        let fact = CareerFact(
            field: field,
            value: value,
            source: source,
            verification: verification,
            updatedAt: updatedAt
        )

        facts.removeAll { $0.field == field }
        facts.append(fact)
    }

    public mutating func removeFact(for field: CanonicalCareerField) {
        facts.removeAll { $0.field == field }
    }
}

public protocol CareerFactsStore: Sendable {
    func load() async throws -> CareerProfile
    func save(_ profile: CareerProfile) async throws
}

public actor JSONCareerFactsStore: CareerFactsStore {
    public let fileURL: URL

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() async throws -> CareerProfile {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return CareerProfile()
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(CareerProfile.self, from: data)
    }

    public func save(_ profile: CareerProfile) async throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        let data = try encoder.encode(profile)
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }
}
