import XCTest
@testable import CareerPilotCore

final class GatewayEndpointPolicyTests: XCTestCase {
    func testLoopbackGatewayIsAllowed() throws {
        let url = try XCTUnwrap(URL(string: "http://127.0.0.1:18789"))
        XCTAssertNoThrow(try GatewayEndpointPolicy.validate(url))
        XCTAssertEqual(
            try GatewayEndpointPolicy.modelsURL(from: url).absoluteString,
            "http://127.0.0.1:18789/v1/models"
        )
    }

    func testRemoteGatewayIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "https://gateway.example.com"))
        XCTAssertThrowsError(try GatewayEndpointPolicy.validate(url)) { error in
            XCTAssertEqual(error as? GatewayEndpointError, .nonLoopbackHost)
        }
    }
}
