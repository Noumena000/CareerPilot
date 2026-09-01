import AppKit
import Foundation
import CareerPilotCore

@MainActor
final class ResumeLibraryStore: ObservableObject {
    @Published private(set) var library = ResumeLibrary()
    @Published var errorMessage: String?

    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let resumesDirectory: URL
    private let metadataURL: URL

    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        baseDirectory = appSupport.appendingPathComponent("CareerPilot", isDirectory: true)
        resumesDirectory = baseDirectory.appendingPathComponent("Resumes", isDirectory: true)
        metadataURL = baseDirectory.appendingPathComponent("resume-library.json")
    }

    func load() {
        do {
            try ensureDirectories()
            guard fileManager.fileExists(atPath: metadataURL.path) else { library = ResumeLibrary(); return }
            let data = try Data(contentsOf: metadataURL)
            library = try JSONDecoder().decode(ResumeLibrary.self, from: data)
            library.resumes.removeAll { !fileManager.fileExists(atPath: resolvedURL(for: $0).path) }
            if let selected = library.selectedResumeID, !library.resumes.contains(where: { $0.id == selected }) {
                library.selectedResumeID = library.resumes.first?.id
            }
        } catch { errorMessage = "Could not load résumé library: \(error.localizedDescription)" }
    }

    func importResume() {
        let panel = NSOpenPanel()
        panel.title = "Import résumé"
        panel.message = "Choose a PDF, DOC, or DOCX résumé. CareerPilot copies it into its private app container."
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = Array(ResumeFilePolicy.allowedExtensions).sorted()
        guard panel.runModal() == .OK, let sourceURL = panel.url else { return }
        importResume(from: sourceURL)
    }

    func select(_ id: UUID) {
        library.select(id)
        persist()
    }

    func remove(_ id: UUID) {
        guard let record = library.resumes.first(where: { $0.id == id }) else { return }
        let url = resolvedURL(for: record)
        try? fileManager.removeItem(at: url)
        library.remove(id)
        persist()
    }

    func selectedResumeURL() -> URL? {
        guard let record = library.selectedResume else { return nil }
        let url = resolvedURL(for: record)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func importResume(from sourceURL: URL) {
        guard ResumeFilePolicy.isAllowed(filename: sourceURL.lastPathComponent) else {
            errorMessage = "CareerPilot accepts PDF, DOC, and DOCX résumés only."
            return
        }
        let gainedAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if gainedAccess { sourceURL.stopAccessingSecurityScopedResource() } }
        do {
            try ensureDirectories()
            let id = UUID()
            let ext = sourceURL.pathExtension.lowercased()
            let storedFilename = "\(id.uuidString).\(ext)"
            let destination = resumesDirectory.appendingPathComponent(storedFilename)
            try fileManager.copyItem(at: sourceURL, to: destination)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
            let displayName = sourceURL.deletingPathExtension().lastPathComponent
            library.add(ResumeRecord(id: id, displayName: displayName, storedFilename: storedFilename, originalFilename: sourceURL.lastPathComponent))
            try save()
            errorMessage = nil
        } catch { errorMessage = "Could not import résumé: \(error.localizedDescription)" }
    }

    private func persist() {
        do { try save(); errorMessage = nil }
        catch { errorMessage = "Could not save résumé library: \(error.localizedDescription)" }
    }

    private func save() throws {
        try ensureDirectories()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(library)
        try data.write(to: metadataURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: metadataURL.path)
    }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: resumesDirectory, withIntermediateDirectories: true)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: baseDirectory.path)
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: resumesDirectory.path)
    }

    private func resolvedURL(for record: ResumeRecord) -> URL {
        resumesDirectory.appendingPathComponent(record.storedFilename, isDirectory: false)
    }
}
