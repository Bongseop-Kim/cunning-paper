import Foundation
import SwiftData

@Model
final class CardModel {
    var id: UUID
    var body: String
    var order: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        body: String,
        order: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.body = body
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var listHeadline: String {
        body
            .split(whereSeparator: \.isWhitespace)
            .first
            .map(String.init) ?? "Empty"
    }

    var listSubheadline: String {
        body
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty } ?? "Empty card"
    }

    var paragraphs: [String] {
        body
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var paragraphCount: Int {
        paragraphs.count
    }

    var paragraphCountLabel: String {
        paragraphCount == 1 ? "1 paragraph" : "\(paragraphCount) paragraphs"
    }
}
