import Foundation
import SwiftData

@Model
final class CardModel {
    var id: UUID
    var title: String
    var body: String
    var order: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        order: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var paragraphs: [String] {
        body
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
