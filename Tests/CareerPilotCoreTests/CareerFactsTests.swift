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
