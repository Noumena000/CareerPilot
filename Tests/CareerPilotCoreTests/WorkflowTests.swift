import XCTest
@testable import CareerPilotCore

final class WorkflowTests: XCTestCase {
    func testReviewedActionReachesVerifiedInOrder() throws {
        var action = WorkflowAction(kind: .writeField)

        for state in [
            WorkflowState.inferred,
            .drafted,
            .awaitingApproval,
            .approved,
            .executed,
            .verified
        ] {
            try action.transition(to: state)
        }

        XCTAssertEqual(action.state, .verified)
    }

    func testActionCannotSkipApproval() {
        var action = WorkflowAction(kind: .writeField)

        XCTAssertThrowsError(try action.transition(to: .executed))
        XCTAssertEqual(action.state, .observed)
    }

    func testSubmissionIsAlwaysUserOnly() {
        var action = WorkflowAction(kind: .submitApplication)

        XCTAssertThrowsError(try action.transition(to: .inferred)) { error in
            XCTAssertEqual(error as? WorkflowError, .submissionIsUserOnly)
        }
    }
}
