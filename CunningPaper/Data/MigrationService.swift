import Foundation
import SwiftData

protocol LegacyCardFileHandling {
    func fileExists(at url: URL) -> Bool
    func data(contentsOf url: URL) throws -> Data
    func removeItem(at url: URL) throws
    func moveItem(at sourceURL: URL, to destinationURL: URL) throws
}

struct DefaultLegacyCardFileHandling: LegacyCardFileHandling {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }

    func data(contentsOf url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func moveItem(at sourceURL: URL, to destinationURL: URL) throws {
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }
}

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
            let title: String?
            let body: String
            let order: Double
            let createdAt: String
            let updatedAt: String
        }

        let decoder = JSONDecoder()
        let legacyCards = try decoder.decode([LegacyCard].self, from: data)
        let formatter = ISO8601DateFormatter()
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return try legacyCards.map { legacyCard in
            guard let id = UUID(uuidString: legacyCard.id) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [],
                    debugDescription: "Invalid legacy card UUID: \(legacyCard.id)"
                ))
            }

            guard let createdAt = parseLegacyDate(
                legacyCard.createdAt,
                standardFormatter: formatter,
                fractionalFormatter: fractionalFormatter
            ) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [],
                    debugDescription: "Invalid legacy card createdAt: \(legacyCard.createdAt)"
                ))
            }

            guard let updatedAt = parseLegacyDate(
                legacyCard.updatedAt,
                standardFormatter: formatter,
                fractionalFormatter: fractionalFormatter
            ) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: [],
                    debugDescription: "Invalid legacy card updatedAt: \(legacyCard.updatedAt)"
                ))
            }

            let normalizedBody = normalizedImportedBody(
                body: legacyCard.body,
                title: legacyCard.title
            )

            return CardModel(
                id: id,
                body: normalizedBody,
                order: legacyCard.order,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }

    private static func normalizedImportedBody(body: String, title: String?) -> String {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedBody.isEmpty {
            return body
        }

        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedTitle
    }

    private static func parseLegacyDate(
        _ value: String,
        standardFormatter: ISO8601DateFormatter,
        fractionalFormatter: ISO8601DateFormatter
    ) -> Date? {
        standardFormatter.date(from: value) ?? fractionalFormatter.date(from: value)
    }

    private static func nextBackupURL(for legacyURL: URL, using fileHandler: LegacyCardFileHandling) -> URL {
        let directory = legacyURL.deletingLastPathComponent()
        let baseName = "cards.json.migrated"
        var candidate = directory.appendingPathComponent(baseName)
        var suffix = 1

        while fileHandler.fileExists(at: candidate) {
            candidate = directory.appendingPathComponent("\(baseName)-\(suffix)")
            suffix += 1
        }

        return candidate
    }

    @MainActor
    static func runIfNeeded(context: ModelContext) {
        runIfNeeded(context: context, legacyCardsURL: legacyCardsPath())
    }

    @MainActor
    static func runIfNeeded(
        context: ModelContext,
        legacyCardsURL: URL?,
        fileHandler: LegacyCardFileHandling = DefaultLegacyCardFileHandling(),
        userDefaults: UserDefaults = .standard
    ) {
        guard !userDefaults.bool(forKey: migrationKey) else { return }

        guard let path = legacyCardsURL, fileHandler.fileExists(at: path) else {
            userDefaults.set(true, forKey: migrationKey)
            return
        }

        var importedCards: [CardModel] = []

        do {
            let data = try fileHandler.data(contentsOf: path)
            let cards = try parseCardsJSON(data)

            cards.forEach { context.insert($0) }
            try context.save()
            importedCards = cards

            let backupURL = nextBackupURL(for: path, using: fileHandler)
            try fileHandler.moveItem(at: path, to: backupURL)

            userDefaults.set(true, forKey: migrationKey)
        } catch {
            if !importedCards.isEmpty {
                importedCards.forEach { context.delete($0) }
                try? context.save()
            }
            return
        }
    }
}
