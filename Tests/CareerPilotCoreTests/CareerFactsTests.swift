import XCTest
@testable import CareerPilotCore

final class CareerFactsTests: XCTestCase {
    func testVerifiedFactsAreUsableForAutomaticFill() {
        let fact = CareerFact(
            field: .email,
            value: "  person@example.com  ",
            verification: .verified
        )

        XCTAssertTrue(fact.isUsableForAutomaticFill)
        XCTAssertEqual(fact.normalizedValue, "person@example.com")
    }

    func testUnverifiedFactsAreNotUsableForAutomaticFill() {
        let fact = CareerFact(
            field: .phone,
            value: "555-0100",
            verification: .unverified
        )

        XCTAssertFalse(fact.isUsableForAutomaticFill)
    }

    func testProfileReturnsOnlyVerifiedValues() {
        var profile = CareerProfile()
        profile.setFact(.email, value: "verified@example.com", verification: .verified)
        profile.setFact(.phone, value: "555-0100", verification: .unverified)

        XCTAssertEqual(profile.verifiedValue(for: .email), "verified@example.com")
        XCTAssertNil(profile.verifiedValue(for: .phone))
    }

    func testFullNameCanBeDerivedOnlyFromVerifiedNameParts() {
        var profile = CareerProfile()
        profile.setFact(.firstName, value: "Taylor", verification: .verified)
        profile.setFact(.lastName, value: "Jordan", verification: .verified)

        XCTAssertEqual(profile.verifiedValue(for: .fullName), "Taylor Jordan")

        profile.setFact(.lastName, value: "Jordan", verification: .unverified)
        XCTAssertNil(profile.verifiedValue(for: .fullName))
    }

    func testReplacingFactKeepsSingleCanonicalValue() {
        var profile = CareerProfile()
        profile.setFact(.city, value: "Old City", verification: .verified)
        profile.setFact(.city, value: "New City", verification: .verified)

        XCTAssertEqual(profile.facts.filter { $0.field == .city }.count, 1)
        XCTAssertEqual(profile.verifiedValue(for: .city), "New City")
    }

    func testUnchangedImportedFactKeepsItsVerificationState() {
        var profile = CareerProfile()
        profile.setFact(
            .linkedInURL,
            value: "https://www.linkedin.com/in/example",
            source: .imported,
            verification: .unverified
        )

        let edited = profile.applyingUserEdits([
            .linkedInURL: "https://www.linkedin.com/in/example"
        ])

        XCTAssertEqual(edited.fact(for: .linkedInURL)?.source, .imported)
        XCTAssertEqual(edited.fact(for: .linkedInURL)?.verification, .unverified)
        XCTAssertNil(edited.verifiedValue(for: .linkedInURL))
    }

    func testChangedImportedFactBecomesUserVerified() {
        var profile = CareerProfile()
        profile.setFact(
            .city,
            value: "Old City",
            source: .imported,
            verification: .unverified
        )

        let edited = profile.applyingUserEdits([.city: "New City"])

        XCTAssertEqual(edited.fact(for: .city)?.source, .userEntered)
        XCTAssertEqual(edited.fact(for: .city)?.verification, .verified)
        XCTAssertEqual(edited.verifiedValue(for: .city), "New City")
    }

    func testClearingUserEditRemovesFact() {
        var profile = CareerProfile()
        profile.setFact(.phone, value: "555-0100", verification: .verified)

        let edited = profile.applyingUserEdits([.phone: "   "])

        XCTAssertNil(edited.fact(for: .phone))
    }

    func testJSONStoreRoundTripsProfile() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = root.appendingPathComponent("career-facts.json")
        defer { try? FileManager.default.removeItem(at: root) }

        let store = JSONCareerFactsStore(fileURL: fileURL)
        var profile = CareerProfile()
        profile.setFact(.firstName, value: "Taylor", verification: .verified)
        profile.setFact(.email, value: "person@example.com", verification: .verified)

        try await store.save(profile)
        let loaded = try await store.load()

        XCTAssertEqual(loaded.verifiedValue(for: .firstName), "Taylor")
        XCTAssertEqual(loaded.verifiedValue(for: .email), "person@example.com")
    }

    func testJSONStoreReturnsEmptyProfileWhenFileDoesNotExist() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("career-facts.json")
        let store = JSONCareerFactsStore(fileURL: fileURL)

        let loaded = try await store.load()

        XCTAssertTrue(loaded.facts.isEmpty)
    }
}
