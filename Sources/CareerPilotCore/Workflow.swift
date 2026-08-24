import Foundation

public enum WorkflowState: String, Codable, CaseIterable, Sendable {
    case observed
    case inferred
    case drafted
    case awaitingApproval
    case approved
    case executed
    case verified
    case rejected
}

public enum WorkflowActionKind: String, Codable, Sendable {
    case analyzeJob
    case draftMaterial
    case proposeFieldWrite
    case writeField
    case submitApplication
}

public enum WorkflowError: Error, Equatable {
    case invalidTransition(from: WorkflowState, to: WorkflowState)
    case submissionIsUserOnly
}

public struct WorkflowAction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: WorkflowActionKind
    public private(set) var state: WorkflowState
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        kind: WorkflowActionKind,
        state: WorkflowState = .observed,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.state = state
        self.createdAt = createdAt
    }

    public mutating func transition(to next: WorkflowState) throws {
        if kind == .submitApplication {
            throw WorkflowError.submissionIsUserOnly
        }

        let allowed: [WorkflowState: Set<WorkflowState>] = [
            .observed: [.inferred],
            .inferred: [.drafted],
            .drafted: [.awaitingApproval],
            .awaitingApproval: [.approved, .rejected],
            .approved: [.executed],
            .executed: [.verified],
            .verified: [],
            .rejected: []
        ]

        guard allowed[state, default: []].contains(next) else {
            throw WorkflowError.invalidTransition(from: state, to: next)
        }

        state = next
    }
}
