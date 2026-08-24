import Foundation

public enum SensitiveFieldCategory: String, Codable, Sendable {
    case routine
    case password
    case identity
    case demographic
    case disability
    case workAuthorization
    case criminalHistory
    case compensation
    case signature
    case fileUpload
    case unknown
}

public struct BrowserFieldDescriptor: Codable, Equatable, Sendable {
    public let reference: String
    public let label: String
    public let name: String
    public let type: String
    public let autocomplete: String?

    public init(
        reference: String,
        label: String,
        name: String = "",
        type: String = "text",
        autocomplete: String? = nil
    ) {
        self.reference = reference
        self.label = label
        self.name = name
        self.type = type
        self.autocomplete = autocomplete
    }
}

public struct FieldProposal: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let field: BrowserFieldDescriptor
    public let proposedValue: String
    public let category: SensitiveFieldCategory
    public var approved: Bool

    public init(
        id: UUID = UUID(),
        field: BrowserFieldDescriptor,
        proposedValue: String,
        category: SensitiveFieldCategory,
        approved: Bool = false
    ) {
        self.id = id
        self.field = field
        self.proposedValue = proposedValue
        self.category = category
        self.approved = approved
    }
}

public enum FieldPolicy {
    public static func classify(_ field: BrowserFieldDescriptor) -> SensitiveFieldCategory {
        let text = [
            field.label,
            field.name,
            field.type,
            field.autocomplete ?? ""
        ]
        .joined(separator: " ")
        .lowercased()

        if field.type.lowercased() == "password" { return .password }
        if field.type.lowercased() == "file" { return .fileUpload }
        if contains(text, ["signature", "certify", "attest"]) { return .signature }
        if contains(text, ["disability", "disabled", "medical condition"]) { return .disability }
        if contains(text, ["race", "ethnicity", "gender", "veteran", "pronoun"]) { return .demographic }
        if contains(text, ["authorized to work", "work authorization", "visa", "sponsorship", "citizenship"]) {
            return .workAuthorization
        }
        if contains(text, ["criminal", "conviction", "felony", "arrest"]) { return .criminalHistory }
        if contains(text, ["salary", "compensation", "desired pay", "pay expectation"]) { return .compensation }
        if contains(text, ["social security", "ssn", "passport", "driver license", "date of birth"]) { return .identity }
        return .routine
    }

    public static func canProgrammaticallyWrite(_ proposal: FieldProposal) -> Bool {
        proposal.approved && proposal.category == .routine
    }

    private static func contains(_ value: String, _ needles: [String]) -> Bool {
        needles.contains { value.contains($0) }
    }
}
