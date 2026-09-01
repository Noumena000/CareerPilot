import XCTest
@testable import CareerPilotCore

final class BrowserTargetIdentityTests: XCTestCase {
    func testTargetIsCurrentOnlyForSameNavigationAndFrame() {
        let navigationID = UUID()
        let page = BrowserPageIdentity(
            navigationID: navigationID,
            url: "https://jobs.example.com/apply",
            frameID: "main"
        )
        let target = BrowserControlTarget(page: page, reference: "email")

        XCTAssertTrue(target.isCurrent(on: page))

        let reloadedPage = BrowserPageIdentity(
            navigationID: UUID(),
            url: "https://jobs.example.com/apply",
            frameID: "main"
        )
        XCTAssertFalse(target.isCurrent(on: reloadedPage))

        let otherFrame = BrowserPageIdentity(
            navigationID: navigationID,
            url: "https://jobs.example.com/apply",
            frameID: "iframe-1"
        )
        XCTAssertFalse(target.isCurrent(on: otherFrame))
    }
}
