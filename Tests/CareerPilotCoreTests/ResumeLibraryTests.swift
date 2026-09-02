import XCTest
@testable import CareerPilotCore

final class ResumeLibraryTests: XCTestCase {
    func testAddingResumeSelectsItByDefault() {
        var library = ResumeLibrary()
        let record = ResumeRecord(displayName: "Product Resume", storedFilename: "a.pdf", originalFilename: "resume.pdf")
        library.add(record)
        XCTAssertEqual(library.selectedResumeID, record.id)
        XCTAssertEqual(library.selectedResume, record)
    }

    func testRemovingSelectedResumeFallsBackToRemainingResume() {
        let first = ResumeRecord(displayName: "First", storedFilename: "a.pdf", originalFilename: "a.pdf")
        let second = ResumeRecord(displayName: "Second", storedFilename: "b.pdf", originalFilename: "b.pdf")
        var library = ResumeLibrary(resumes: [first, second], selectedResumeID: second.id)
        library.remove(second.id)
        XCTAssertEqual(library.selectedResumeID, first.id)
    }

    func testUnsupportedResumeExtensionIsRejected() {
        XCTAssertTrue(ResumeFilePolicy.isAllowed(filename: "resume.pdf"))
        XCTAssertTrue(ResumeFilePolicy.isAllowed(filename: "resume.DOCX"))
        XCTAssertFalse(ResumeFilePolicy.isAllowed(filename: "resume.pages"))
        XCTAssertFalse(ResumeFilePolicy.isAllowed(filename: "script.js"))
    }

    func testStoredResumeFilenameMustStayInsideLibraryAndMatchRecordID() {
        let id = UUID()
        XCTAssertTrue(ResumeFilePolicy.isSafeStoredFilename("\(id.uuidString).pdf", for: id))
        XCTAssertTrue(ResumeFilePolicy.isSafeStoredFilename("\(id.uuidString).DOCX", for: id))
        XCTAssertFalse(ResumeFilePolicy.isSafeStoredFilename("../\(id.uuidString).pdf", for: id))
        XCTAssertFalse(ResumeFilePolicy.isSafeStoredFilename("other-id.pdf", for: id))
        XCTAssertFalse(ResumeFilePolicy.isSafeStoredFilename("\(id.uuidString).pages", for: id))
    }
}
