import XCTest
@testable import CareerPilotCore

final class CareerFieldMatcherTests: XCTestCase {
    private func verifiedProfile() -> CareerProfile {
        var profile = CareerProfile()
        profile.setFact(.firstName, value: "Taylor", verification: .verified)
        profile.setFact(.lastName, value: "Jordan", verification: .verified)
        profile.setFact(.email, value: "person@example.com", verification: .verified)
        profile.setFact(.phone, value: "555-0100", verification: .verified)
        profile.setFact(.city, value: "Albany", verification: .verified)
        profile.setFact(.state, value: "NY", verification: .verified)
        profile.setFact(.postalCode, value: "12203", verification: .verified)
        profile.setFact(.linkedInURL, value: "https://www.linkedin.com/in/example", verification: .verified)
        profile.setFact(.portfolioURL, value: "https://portfolio.example", verification: .verified)
        return profile
    }

    func testAutocompleteProvidesExactMatch() {
        let field = BrowserFieldDescriptor(
            reference: "first",
            label: "",
            autocomplete: "section-applicant given-name"
        )

        let match = CareerFieldMatcher.match(field, against: verifiedProfile())

        XCTAssertEqual(match?.canonicalField, .firstName)
        XCTAssertEqual(match?.value, "Taylor")
        XCTAssertEqual(match?.confidence, .exact)
    }

    func testCamelCaseNameMatchesDeterministically() {
        let field = BrowserFieldDescriptor(
            reference: "last",
            label: "",
            name: "lastName"
        )

        let match = CareerFieldMatcher.match(field, against: verifiedProfile())

        XCTAssertEqual(match?.canonicalField, .lastName)
        XCTAssertEqual(match?.value, "Jordan")
    }

    func testInputTypeCanIdentifyEmailAndPhone() {
        let email = BrowserFieldDescriptor(reference: "email", label: "Contact", type: "email")
        let phone = BrowserFieldDescriptor(reference: "phone", label: "Contact", type: "tel")

        XCTAssertEqual(CareerFieldMatcher.match(email, against: verifiedProfile())?.canonicalField, .email)
        XCTAssertEqual(CareerFieldMatcher.match(phone, against: verifiedProfile())?.canonicalField, .phone)
    }

    func testAriaLabelAndPlaceholderAreRecognized() {
        let linkedIn = BrowserFieldDescriptor(
            reference: "social",
            label: "",
            ariaLabel: "LinkedIn profile"
        )
        let postal = BrowserFieldDescriptor(
            reference: "postal",
            label: "",
            placeholder: "ZIP code"
        )

        XCTAssertEqual(CareerFieldMatcher.match(linkedIn, against: verifiedProfile())?.canonicalField, .linkedInURL)
        XCTAssertEqual(CareerFieldMatcher.match(postal, against: verifiedProfile())?.canonicalField, .postalCode)
    }

    func testUnverifiedCareerFactNeverProducesMatch() {
        var profile = verifiedProfile()
        profile.setFact(.email, value: "unverified@example.com", verification: .unverified)
        let field = BrowserFieldDescriptor(reference: "email", label: "Email address")

        XCTAssertNil(CareerFieldMatcher.match(field, against: profile))
    }

    func testSensitiveFieldNeverProducesCareerFactMatch() {
        var profile = verifiedProfile()
        profile.setFact(.websiteURL, value: "https://example.com", verification: .verified)
        let field = BrowserFieldDescriptor(
            reference: "identity",
            label: "Social Security Number",
            placeholder: "SSN"
        )

        XCTAssertEqual(FieldPolicy.classify(field), .identity)
        XCTAssertNil(CareerFieldMatcher.match(field, against: profile))
    }

    func testNearbyTextAloneIsInsufficientForAutomaticMatch() {
        let field = BrowserFieldDescriptor(
            reference: "mystery",
            label: "",
            nearbyText: "Email address"
        )

        XCTAssertNil(CareerFieldMatcher.match(field, against: verifiedProfile()))
    }

    func testFullNameCanUseVerifiedDerivedValue() {
        let field = BrowserFieldDescriptor(reference: "full", label: "Full name")

        let match = CareerFieldMatcher.match(field, against: verifiedProfile())

        XCTAssertEqual(match?.canonicalField, .fullName)
        XCTAssertEqual(match?.value, "Taylor Jordan")
    }

    func testAmbiguousGenericControlDoesNotMatch() {
        let field = BrowserFieldDescriptor(reference: "unknown", label: "Contact information")

        XCTAssertNil(CareerFieldMatcher.match(field, against: verifiedProfile()))
    }
}
