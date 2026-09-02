import Foundation

public struct ResumeRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var displayName: String
    public let storedFilename: String
    public let originalFilename: String
    public let importedAt: Date

    public init(
        id: UUID = UUID(),
        displayName: String,
        storedFilename: String,
        originalFilename: String,
        importedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.storedFilename = storedFilename
        self.originalFilename = originalFilename
        self.importedAt = importedAt
    }
}

public struct ResumeLibrary: Codable, Equatable, Sendable {
    public var resumes: [ResumeRecord]
    public var selectedResumeID: UUID?

    public init(resumes: [ResumeRecord] = [], selectedResumeID: UUID? = nil) {
        self.resumes = resumes
        self.selectedResumeID = selectedResumeID
    }

    public var selectedResume: ResumeRecord? {
        guard let selectedResumeID else { return nil }
        return resumes.first { $0.id == selectedResumeID }
    }

    public mutating func add(_ resume: ResumeRecord, select: Bool = true) {
        resumes.removeAll { $0.id == resume.id || $0.storedFilename == resume.storedFilename }
        resumes.append(resume)
        if select { selectedResumeID = resume.id }
    }

    public mutating func select(_ id: UUID?) {
        guard let id else { selectedResumeID = nil; return }
        selectedResumeID = resumes.contains(where: { $0.id == id }) ? id : selectedResumeID
    }

    public mutating func remove(_ id: UUID) {
        resumes.removeAll { $0.id == id }
        if selectedResumeID == id { selectedResumeID = resumes.first?.id }
    }
}

public enum ResumeFilePolicy {
    public static let allowedExtensions: Set<String> = ["pdf", "doc", "docx"]

    public static func isAllowed(filename: String) -> Bool {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        return allowedExtensions.contains(ext)
    }

    public static func isSafeStoredFilename(_ filename: String, for id: UUID) -> Bool {
        guard filename == URL(fileURLWithPath: filename).lastPathComponent,
              !filename.contains("/"),
              !filename.contains("\\"),
              isAllowed(filename: filename) else {
            return false
        }

        let url = URL(fileURLWithPath: filename)
        return url.deletingPathExtension().lastPathComponent.lowercased() == id.uuidString.lowercased()
    }
}
