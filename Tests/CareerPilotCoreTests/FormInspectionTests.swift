import XCTest
@testable import CareerPilotCore

final class FormInspectionTests: XCTestCase {
    private let secureURL = URL(string: "https://jobs.example.com/apply")!

    func testPlannerProposesVerifiedRoutineFactForEmptyField() {
        var profile = CareerProfile()
        profile.setFact(.email, value: "candidate@example.com", verification: .verified)
        let field = inspected(label: "Email", type: "email")

        let proposals = RoutineFillPlanner.proposals(for: [field], profile: profile, pageURL: secureURL)

        XCTAssertEqual(proposals.count, 1)
        XCTAssertEqual(proposals.first?.canonicalField, .email)
        XCTAssertEqual(proposals.first?.proposedValue, "candidate@example.com")
    }

    func testPlannerPreservesExistingUserValue() {
        var profile = CareerProfile()
        profile.setFact(.email, value: "candidate@example.com", verification: .verified)
        let field = inspected(label: "Email", type: "email", currentValue: "already@entered.example")

        XCTAssertTrue(RoutineFillPlanner.proposals(for: [field], profile: profile, pageURL: secureURL).isEmpty)
    }

    func testPlannerRejectsHTTPDisclosure() {
        var profile = CareerProfile()
        profile.setFact(.email, value: "candidate@example.com", verification: .verified)
        let field = inspected(label: "Email", type: "email")

        XCTAssertTrue(RoutineFillPlanner.proposals(
            for: [field],
            profile: profile,
            pageURL: URL(string: "http://jobs.example.com/apply")
        ).isEmpty)
    }

    func testPlannerRejectsSensitiveDisabledAndReadOnlyFields() {
        var profile = CareerProfile()
        profile.setFact(.email, value: "candidate@example.com", verification: .verified)

        let sensitive = inspected(label: "Social Security Number", name: "ssn")
        let disabled = inspected(label: "Email", type: "email", isDisabled: true)
        let readOnly = inspected(label: "Email", type: "email", isReadOnly: true)

        XCTAssertTrue(RoutineFillPlanner.proposals(
            for: [sensitive, disabled, readOnly],
            profile: profile,
            pageURL: secureURL
        ).isEmpty)
    }

    private func inspected(
        label: String,
        name: String = "",
        type: String = "text",
        currentValue: String = "",
        isDisabled: Bool = false,
        isReadOnly: Bool = false
    ) -> InspectedBrowserField {
        let descriptor = BrowserFieldDescriptor(
            reference: "field-1",
            label: label,
            name: name,
            type: type
        )
        let page = BrowserPageIdentity(url: secureURL.absoluteString)
        return InspectedBrowserField(
            descriptor: descriptor,
            target: BrowserControlTarget(page: page, reference: descriptor.reference),
            currentValue: currentValue,
            isDisabled: isDisabled,
            isReadOnly: isReadOnly
        )
    }
}
