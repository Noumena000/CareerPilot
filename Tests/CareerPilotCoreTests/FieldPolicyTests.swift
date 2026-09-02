import XCTest
@testable import CareerPilotCore

final class FieldPolicyTests: XCTestCase {
    func testRoutineFieldRequiresApproval() {
        let field = BrowserFieldDescriptor(reference: "first-name", label: "First name", name: "firstName")
        let unapproved = FieldProposal(
            field: field,
            proposedValue: "Taylor",
            category: FieldPolicy.classify(field)
        )
        var approved = unapproved
        approved.approved = true

        XCTAssertFalse(FieldPolicy.canProgrammaticallyWrite(unapproved))
        XCTAssertTrue(FieldPolicy.canProgrammaticallyWrite(approved))
    }

    func testSensitiveFieldsStayManual() {
        let fields = [
            BrowserFieldDescriptor(reference: "visa", label: "Will you require visa sponsorship?"),
            BrowserFieldDescriptor(reference: "salary", label: "Desired salary"),
            BrowserFieldDescriptor(reference: "disability", label: "Disability status"),
            BrowserFieldDescriptor(reference: "signature", label: "I certify this application")
        ]

        for field in fields {
            let proposal = FieldProposal(
                field: field,
                proposedValue: "Yes",
                category: FieldPolicy.classify(field),
                approved: true
            )
            XCTAssertFalse(FieldPolicy.canProgrammaticallyWrite(proposal))
        }
    }

    func testSensitiveClassificationUsesAriaPlaceholderAndNearbyText() {
        XCTAssertEqual(
            FieldPolicy.classify(
                BrowserFieldDescriptor(reference: "a", label: "", ariaLabel: "Disability status")
            ),
            .disability
        )
        XCTAssertEqual(
            FieldPolicy.classify(
                BrowserFieldDescriptor(reference: "b", label: "", placeholder: "SSN")
            ),
            .identity
        )
        XCTAssertEqual(
            FieldPolicy.classify(
                BrowserFieldDescriptor(reference: "c", label: "", nearbyText: "Desired salary")
            ),
            .compensation
        )
    }
}
