import Foundation
import SwiftData

enum CunningPaperSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            CunningPaperSchemaV1.CardModel.self,
            CunningPaperSchemaV1.PrefsModel.self,
        ]
    }
}

enum CunningPaperSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            CunningPaperSchemaV2.CardModel.self,
            CunningPaperSchemaV2.PrefsModel.self,
        ]
    }
}

enum CunningPaperSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { .init(3, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            CunningPaperSchemaV3.CardModel.self,
            CunningPaperSchemaV3.PrefsModel.self,
        ]
    }
}

extension CunningPaperSchemaV1 {
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
    }
}

extension CunningPaperSchemaV2 {
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
    }
}

extension CunningPaperSchemaV3 {
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
}

typealias CardModel = CunningPaperSchemaV3.CardModel
