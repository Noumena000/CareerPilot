import Foundation

public struct InspectedBrowserField: Codable, Equatable, Sendable {
    public let descriptor: BrowserFieldDescriptor
    public let target: BrowserControlTarget
    public let currentValue: String
    public let isDisabled: Bool
    public let isReadOnly: Bool

    public init(
        descriptor: BrowserFieldDescriptor,
        target: BrowserControlTarget,
        currentValue: String = "",
        isDisabled: Bool = false,
        isReadOnly: Bool = false
    ) {
        self.descriptor = descriptor
        self.target = target
        self.currentValue = currentValue
        self.isDisabled = isDisabled
        self.isReadOnly = isReadOnly
    }
}

public struct RoutineFillProposal: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let inspectedField: InspectedBrowserField
    public let canonicalField: CanonicalCareerField
    public let proposedValue: String
    public let confidence: FieldMatchConfidence
    public let evidence: String

    public init(
        id: UUID = UUID(),
        inspectedField: InspectedBrowserField,
        canonicalField: CanonicalCareerField,
        proposedValue: String,
        confidence: FieldMatchConfidence,
        evidence: String
    ) {
        self.id = id
        self.inspectedField = inspectedField
        self.canonicalField = canonicalField
        self.proposedValue = proposedValue
        self.confidence = confidence
        self.evidence = evidence
    }
}

public enum RoutineFillPlanner {
    public static func proposals(
        for fields: [InspectedBrowserField],
        profile: CareerProfile,
        pageURL: URL?
    ) -> [RoutineFillProposal] {
        guard ApplicationURLPolicy.permitsAutomaticDisclosure(to: pageURL) else { return [] }

        return fields.compactMap { field in
            guard !field.isDisabled,
                  !field.isReadOnly,
                  field.currentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let match = CareerFieldMatcher.match(field.descriptor, against: profile) else {
                return nil
            }

            return RoutineFillProposal(
                inspectedField: field,
                canonicalField: match.canonicalField,
                proposedValue: match.value,
                confidence: match.confidence,
                evidence: match.evidence
            )
        }
    }
}
