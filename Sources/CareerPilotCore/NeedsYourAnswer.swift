import Foundation

public enum ReviewReason: String, Codable, Sendable {
    case sensitive
    case unknown
    case unsupported
    case verificationRequired
    case judgmentRequired
}

public struct ReviewQuestion: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let inspectedField: InspectedBrowserField
    public let reason: ReviewReason
    public let category: SensitiveFieldCategory
    public let explanation: String

    public init(
        inspectedField: InspectedBrowserField,
        reason: ReviewReason,
        category: SensitiveFieldCategory,
        explanation: String
    ) {
        self.id = inspectedField.target.reference
        self.inspectedField = inspectedField
        self.reason = reason
        self.category = category
        self.explanation = explanation
    }
}

public enum NeedsYourAnswerPlanner {
    public static func questions(
        for fields: [InspectedBrowserField],
        routineProposals: [RoutineFillProposal]
    ) -> [ReviewQuestion] {
        let proposedReferences = Set(routineProposals.map { $0.inspectedField.target.reference })

        return fields.compactMap { field in
            guard !field.isDisabled,
                  !field.isReadOnly,
                  field.currentValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !proposedReferences.contains(field.target.reference) else {
                return nil
            }

            let category = FieldPolicy.classify(field.descriptor)
            if category != .routine {
                return ReviewQuestion(
                    inspectedField: field,
                    reason: .sensitive,
                    category: category,
                    explanation: explanation(for: category)
                )
            }

            let type = field.descriptor.type.lowercased()
            if ["checkbox", "radio", "date", "datetime-local", "month", "week", "time", "number", "range", "color", "file"].contains(type) {
                return ReviewQuestion(
                    inspectedField: field,
                    reason: .unsupported,
                    category: category,
                    explanation: "CareerPilot does not automatically answer this control type yet."
                )
            }

            let text = field.descriptor.matchingText
            if contains(text, ["why do you want", "why are you interested", "tell us", "describe", "explain", "cover letter", "additional information", "anything else"]) {
                return ReviewQuestion(
                    inspectedField: field,
                    reason: .judgmentRequired,
                    category: category,
                    explanation: "This question requires a contextual or judgment-based answer, so CareerPilot will not invent one."
                )
            }

            return ReviewQuestion(
                inspectedField: field,
                reason: .unknown,
                category: category,
                explanation: "No verified CareerFact safely matched this empty field."
            )
        }
    }

    private static func explanation(for category: SensitiveFieldCategory) -> String {
        switch category {
        case .password: return "Passwords and authentication information always require you."
        case .identity: return "Identity information is sensitive and is never filled automatically."
        case .demographic: return "Demographic questions remain under your direct control."
        case .disability: return "Disability and medical questions remain under your direct control."
        case .workAuthorization: return "Work-authorization answers can have legal consequences and require your confirmation."
        case .criminalHistory: return "Criminal-history questions require your direct review."
        case .compensation: return "Compensation expectations require your judgment."
        case .signature: return "Certifications, attestations, and signatures require your explicit action."
        case .fileUpload: return "File uploads require an explicitly selected file and are handled separately."
        case .unknown: return "CareerPilot could not safely classify this field."
        case .routine: return "This field requires your review."
        }
    }

    private static func contains(_ value: String, _ needles: [String]) -> Bool {
        needles.contains { value.contains($0) }
    }
}
