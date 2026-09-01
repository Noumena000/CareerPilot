import Foundation

public struct BrowserPageIdentity: Codable, Equatable, Hashable, Sendable {
    public let navigationID: UUID
    public let url: String
    public let frameID: String

    public init(
        navigationID: UUID = UUID(),
        url: String,
        frameID: String = "main"
    ) {
        self.navigationID = navigationID
        self.url = url
        self.frameID = frameID
    }
}

public struct BrowserControlTarget: Codable, Equatable, Hashable, Sendable {
    public let page: BrowserPageIdentity
    public let reference: String

    public init(page: BrowserPageIdentity, reference: String) {
        self.page = page
        self.reference = reference
    }

    public func isCurrent(on currentPage: BrowserPageIdentity) -> Bool {
        page == currentPage
    }
}
