import Foundation
import SwiftData

enum MigrationService {
    private static let migrationKey = "cunningPaper.migration.v1.complete"

    static func needsMigration() -> Bool {
        !UserDefaults.standard.bool(forKey: migrationKey)
    }

    static func legacyCardsPath() -> URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("lens-note")
            .appendingPathComponent("cards.json")
    }

    static func parseCardsJSON(_ data: Data) throws -> [CardModel] {
        struct LegacyCard: Decodable {
            let id: String
            let title: String
            let body: String
            let order: Double
            let createdAt: String
            let updatedAt: String
        }

        let decoder = JSONDecoder()
        let legacyCards = try decoder.decode([LegacyCard].self, from: data)
        let formatter = ISO8601DateFormatter()

        return legacyCards.map { legacyCard in
            CardModel(
                id: UUID(uuidString: legacyCard.id) ?? UUID(),
                title: legacyCard.title,
                body: legacyCard.body,
                order: legacyCard.order,
                createdAt: formatter.date(from: legacyCard.createdAt) ?? Date(),
                updatedAt: formatter.date(from: legacyCard.updatedAt) ?? Date()
            )
        }
    }

    @MainActor
    static func runIfNeeded(context: ModelContext) {
        guard needsMigration() else { return }

        guard
            let path = legacyCardsPath(),
            FileManager.default.fileExists(atPath: path.path),
            let data = try? Data(contentsOf: path),
            let cards = try? parseCardsJSON(data)
        else {
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        cards.forEach { context.insert($0) }
        try? context.save()

        let backupURL = path.deletingLastPathComponent().appendingPathComponent("cards.json.migrated")
        try? FileManager.default.removeItem(at: backupURL)
        try? FileManager.default.moveItem(at: path, to: backupURL)

        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
