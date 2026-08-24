import Foundation

public enum ApplicationStage: String, Codable, CaseIterable, Sendable {
    case discovered
    case reviewing
    case preparing
    case ready
    case submitted
    case interviewing
    case closed
}

public struct JobPosting: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var company: String
    public var sourceURL: URL
    public var capturedAt: Date
    public var descriptionText: String

    public init(
        id: UUID = UUID(),
        title: String,
        company: String,
        sourceURL: URL,
        capturedAt: Date = Date(),
        descriptionText: String
    ) {
        self.id = id
        self.title = title
        self.company = company
        self.sourceURL = sourceURL
        self.capturedAt = capturedAt
        self.descriptionText = descriptionText
    }
}

public struct ApplicationRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var job: JobPosting
    public var stage: ApplicationStage
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        job: JobPosting,
        stage: ApplicationStage = .discovered,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.job = job
        self.stage = stage
        self.updatedAt = updatedAt
    }
}
