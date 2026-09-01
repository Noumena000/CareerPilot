import Foundation

public enum FillAttemptStatus: String, Codable, Equatable, Sendable {
    case verified
    case staleTarget
    case targetMissing
    case targetMismatch
    case existingValuePreserved
    case unsupportedControl
    case writeFailed
    case readbackFailed
}

public struct FillAttemptResult: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let proposalID: UUID
    public let canonicalField: CanonicalCareerField
    public let status: FillAttemptStatus
    public let readbackValue: String?
    public let message: String

    public init(
        id: UUID = UUID(),
        proposalID: UUID,
        canonicalField: CanonicalCareerField,
        status: FillAttemptStatus,
        readbackValue: String? = nil,
        message: String
    ) {
        self.id = id
        self.proposalID = proposalID
        self.canonicalField = canonicalField
        self.status = status
        self.readbackValue = readbackValue
        self.message = message
    }

    public var succeeded: Bool { status == .verified }
}

public enum FillExecutionPolicy {
    public static func permitsAttempt(
        _ proposal: RoutineFillProposal,
        currentPage: BrowserPageIdentity?,
        currentURL: URL?
    ) -> Bool {
        guard ApplicationURLPolicy.permitsAutomaticDisclosure(to: currentURL),
              let currentPage else { return false }
        return proposal.inspectedField.target.isCurrent(on: currentPage)
    }
}
