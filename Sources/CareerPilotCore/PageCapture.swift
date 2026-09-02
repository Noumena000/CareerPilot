import Foundation

public struct CapturedPageField: Codable, Equatable, Sendable, Identifiable {
    public var id: String { reference }
    public let reference: String
    public let label: String
    public let name: String
    public let type: String
    public let autocomplete: String
    public let required: Bool
    public let disabled: Bool

    public init(
        reference: String,
        label: String,
        name: String,
        type: String,
        autocomplete: String = "",
        required: Bool = false,
        disabled: Bool = false
    ) {
        self.reference = reference
        self.label = label
        self.name = name
        self.type = type
        self.autocomplete = autocomplete
        self.required = required
        self.disabled = disabled
    }
}

public struct BrowserPageCapture: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let url: String
    public let title: String
    public let capturedAt: Date
    public let text: String
    public let fields: [CapturedPageField]

    public init(
        id: UUID = UUID(),
        url: String,
        title: String,
        capturedAt: Date = Date(),
        text: String,
        fields: [CapturedPageField]
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.capturedAt = capturedAt
        self.text = text
        self.fields = fields
    }

    private enum CodingKeys: String, CodingKey { case id, url, title, capturedAt, text, fields }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        url = try container.decode(String.self, forKey: .url)
        title = try container.decode(String.self, forKey: .title)
        capturedAt = try container.decode(Date.self, forKey: .capturedAt)
        text = try container.decode(String.self, forKey: .text)
        fields = try container.decode([CapturedPageField].self, forKey: .fields)
    }
}
