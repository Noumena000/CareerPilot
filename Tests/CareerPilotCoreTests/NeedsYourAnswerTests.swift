import XCTest
@testable import CareerPilotCore

final class NeedsYourAnswerTests: XCTestCase {
    func testSensitiveFieldRequiresUserAnswer() {
        let field = inspected(label: "Desired salary")
        let questions = NeedsYourAnswerPlanner.questions(for: [field], routineProposals: [])
        XCTAssertEqual(questions.first?.reason, .sensitive)
        XCTAssertEqual(questions.first?.category, .compensation)
    }

    func testJudgmentQuestionRequiresUserAnswer() {
        let field = inspected(label: "Why do you want to work here?", type: "textarea")
        let questions = NeedsYourAnswerPlanner.questions(for: [field], routineProposals: [])
        XCTAssertEqual(questions.first?.reason, .judgmentRequired)
    }

    func testUnsupportedControlRequiresUserAnswer() {
        let field = inspected(label: "Are you willing to relocate?", type: "radio")
        let questions = NeedsYourAnswerPlanner.questions(for: [field], routineProposals: [])
        XCTAssertEqual(questions.first?.reason, .unsupported)
    }

    func testRoutineProposalIsNotDuplicatedInReviewQueue() {
        let field = inspected(label: "Email", type: "email")
        let proposal = RoutineFillProposal(
            inspectedField: field,
            canonicalField: .email,
            proposedValue: "candidate@example.com",
            confidence: .high,
            evidence: "email input"
        )
        XCTAssertTrue(NeedsYourAnswerPlanner.questions(for: [field], routineProposals: [proposal]).isEmpty)
    }

    func testExistingValueIsNotAddedToReviewQueue() {
        let field = inspected(label: "Portfolio", type: "url", currentValue: "https://example.com")
        XCTAssertTrue(NeedsYourAnswerPlanner.questions(for: [field], routineProposals: []).isEmpty)
    }

    private func inspected(label: String, type: String = "text", currentValue: String = "") -> InspectedBrowserField {
        let descriptor = BrowserFieldDescriptor(reference: "field-1", label: label, type: type)
        let page = BrowserPageIdentity(url: "https://jobs.example.com/apply")
        return InspectedBrowserField(
            descriptor: descriptor,
            target: BrowserControlTarget(page: page, reference: descriptor.reference),
            currentValue: currentValue
        )
    }
}
