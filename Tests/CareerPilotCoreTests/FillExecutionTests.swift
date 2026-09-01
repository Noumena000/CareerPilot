import XCTest
@testable import CareerPilotCore

final class FillExecutionTests: XCTestCase {
    func testFillAttemptRequiresCurrentHTTPSPage() {
        let page = BrowserPageIdentity(url: "https://jobs.example.com/apply")
        let proposal = makeProposal(page: page)

        XCTAssertTrue(FillExecutionPolicy.permitsAttempt(
            proposal,
            currentPage: page,
            currentURL: URL(string: "https://jobs.example.com/apply")
        ))
        XCTAssertFalse(FillExecutionPolicy.permitsAttempt(
            proposal,
            currentPage: page,
            currentURL: URL(string: "http://jobs.example.com/apply")
        ))
    }

    func testFillAttemptRejectsStaleNavigationIdentity() {
        let observed = BrowserPageIdentity(url: "https://jobs.example.com/apply")
        let current = BrowserPageIdentity(url: "https://jobs.example.com/apply")
        let proposal = makeProposal(page: observed)

        XCTAssertFalse(FillExecutionPolicy.permitsAttempt(
            proposal,
            currentPage: current,
            currentURL: URL(string: "https://jobs.example.com/apply")
        ))
    }

    private func makeProposal(page: BrowserPageIdentity) -> RoutineFillProposal {
        let descriptor = BrowserFieldDescriptor(reference: "cp-0", label: "Email", type: "email")
        let inspected = InspectedBrowserField(
            descriptor: descriptor,
            target: BrowserControlTarget(page: page, reference: descriptor.reference)
        )
        return RoutineFillProposal(
            inspectedField: inspected,
            canonicalField: .email,
            proposedValue: "candidate@example.com",
            confidence: .exact,
            evidence: "type=email"
        )
    }
}
