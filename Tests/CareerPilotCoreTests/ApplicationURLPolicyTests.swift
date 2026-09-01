import XCTest
@testable import CareerPilotCore

final class ApplicationURLPolicyTests: XCTestCase {
    func testAddsHTTPSWhenSchemeIsMissing() throws {
        let url = try ApplicationURLPolicy.resolve("careers.example.com/apply/123")

        XCTAssertEqual(url.absoluteString, "https://careers.example.com/apply/123")
    }

    func testPreservesExplicitHTTPSURL() throws {
        let url = try ApplicationURLPolicy.resolve("https://jobs.example.com/apply?id=42")

        XCTAssertEqual(url.absoluteString, "https://jobs.example.com/apply?id=42")
    }

    func testRejectsNonWebSchemes() {
        XCTAssertThrowsError(try ApplicationURLPolicy.resolve("file:///tmp/private.txt")) { error in
            XCTAssertEqual(error as? ApplicationURLPolicyError, .unsupportedScheme("file"))
        }

        XCTAssertThrowsError(try ApplicationURLPolicy.resolve("javascript:alert(1)")) { error in
            XCTAssertEqual(error as? ApplicationURLPolicyError, .unsupportedScheme("javascript"))
        }

        XCTAssertThrowsError(try ApplicationURLPolicy.resolve("mailto:test@example.com")) { error in
            XCTAssertEqual(error as? ApplicationURLPolicyError, .unsupportedScheme("mailto"))
        }
    }

    func testNavigationPolicyAllowsOnlyWebAndAboutPages() {
        XCTAssertTrue(ApplicationURLPolicy.permitsNavigation(to: URL(string: "https://example.com")))
        XCTAssertTrue(ApplicationURLPolicy.permitsNavigation(to: URL(string: "http://example.com")))
        XCTAssertTrue(ApplicationURLPolicy.permitsNavigation(to: URL(string: "about:blank")))
        XCTAssertFalse(ApplicationURLPolicy.permitsNavigation(to: URL(string: "file:///tmp/test")))
        XCTAssertFalse(ApplicationURLPolicy.permitsNavigation(to: URL(string: "mailto:test@example.com")))
    }

    func testEmptyAndMalformedValuesFailClosed() {
        XCTAssertThrowsError(try ApplicationURLPolicy.resolve("   ")) { error in
            XCTAssertEqual(error as? ApplicationURLPolicyError, .empty)
        }
        XCTAssertThrowsError(try ApplicationURLPolicy.resolve("https://"))
    }
}
