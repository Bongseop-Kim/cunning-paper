import SwiftData
import XCTest
@testable import CunningPaper

final class MigrationServiceTests: XCTestCase {
    @MainActor
    func testCurrentSchemaLoadsExistingBodyOnlyStore() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("default.store")
        try FileManager.default.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent())
        }

        let legacySchema = Schema(versionedSchema: CunningPaperSchemaV1.self)
        let legacyConfig = ModelConfiguration(
            schema: legacySchema,
            url: storeURL
        )
        let legacyContainer = try ModelContainer(
            for: legacySchema,
            configurations: legacyConfig
        )
        let legacyContext = ModelContext(legacyContainer)
        legacyContext.insert(CunningPaperSchemaV1.CardModel(body: "Persisted body"))
        legacyContext.insert(CunningPaperSchemaV1.PrefsModel())
        try legacyContext.save()

        let currentSchema = Schema(versionedSchema: CunningPaperSchemaV3.self)
        let currentConfig = ModelConfiguration(
            schema: currentSchema,
            url: storeURL
        )

        let currentContainer = try XCTUnwrap(
            try? ModelContainer(
                for: currentSchema,
                migrationPlan: CunningPaperMigrationPlan.self,
                configurations: [currentConfig]
            )
        )
        let currentContext = ModelContext(currentContainer)
        let cards = try currentContext.fetch(FetchDescriptor<CardModel>())
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards.first?.body, "Persisted body")
    }

    func testParseCardsJSONReturnsCards() throws {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello world\\nSecond line","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """

        let cards = try MigrationService.parseCardsJSON(Data(json.utf8))
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].body, "Hello world\nSecond line")
        XCTAssertEqual(cards[0].listHeadline, "Hello")
        XCTAssertEqual(cards[0].listSubheadline, "Hello world")
        XCTAssertEqual(cards[0].order, 0)
        XCTAssertEqual(cards[0].createdAt, ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z"))
        XCTAssertEqual(cards[0].updatedAt, ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z"))
    }

    func testParseCardsJSONAcceptsFractionalSecondTimestamps() throws {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00.000Z","updatedAt":"2024-01-01T00:00:00.250Z"}]
        """

        let cards = try MigrationService.parseCardsJSON(Data(json.utf8))
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].createdAt, ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z"))
        let updatedFormatter = ISO8601DateFormatter()
        updatedFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertEqual(cards[0].updatedAt, updatedFormatter.date(from: "2024-01-01T00:00:00.250Z"))
    }

    func testParseCardsJSONAllowsMissingLegacyTitle() throws {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","body":"Hello world","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """

        let cards = try MigrationService.parseCardsJSON(Data(json.utf8))
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].body, "Hello world")
        XCTAssertEqual(cards[0].listHeadline, "Hello")
        XCTAssertEqual(cards[0].listSubheadline, "Hello world")
    }

    func testParseCardsJSONPromotesLegacyTitleWhenBodyEmpty() throws {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Legacy intro","body":"  ","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """

        let cards = try MigrationService.parseCardsJSON(Data(json.utf8))
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].body, "Legacy intro")
        XCTAssertEqual(cards[0].listHeadline, "Legacy")
        XCTAssertEqual(cards[0].listSubheadline, "Legacy intro")
    }

    func testParseCardsJSONTrimsNonEmptyLegacyBody() throws {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"  Hello world\\nSecond line  ","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """

        let cards = try MigrationService.parseCardsJSON(Data(json.utf8))
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].body, "Hello world\nSecond line")
    }

    func testParseCardsJSONEmptyArray() throws {
        let cards = try MigrationService.parseCardsJSON(Data("[]".utf8))
        XCTAssertTrue(cards.isEmpty)
    }

    func testParseCardsJSONRejectsInvalidUUID() {
        let json = """
        [{"id":"not-a-uuid","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """

        XCTAssertThrowsError(try MigrationService.parseCardsJSON(Data(json.utf8))) { error in
            guard case let DecodingError.dataCorrupted(context) = error else {
                return XCTFail("Expected dataCorrupted error, got \(error)")
            }
            XCTAssertTrue(context.debugDescription.contains("Invalid legacy card UUID"))
        }
    }

    func testParseCardsJSONRejectsInvalidDates() {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"not-a-date","updatedAt":"2024-01-01T00:00:00Z"}]
        """

        XCTAssertThrowsError(try MigrationService.parseCardsJSON(Data(json.utf8))) { error in
            guard case let DecodingError.dataCorrupted(context) = error else {
                return XCTFail("Expected dataCorrupted error, got \(error)")
            }
            XCTAssertTrue(context.debugDescription.contains("Invalid legacy card createdAt"))
        }
    }

    func testParseCardsJSONRejectsInvalidUpdatedAt() {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"not-a-date"}]
        """

        XCTAssertThrowsError(try MigrationService.parseCardsJSON(Data(json.utf8))) { error in
            guard case let DecodingError.dataCorrupted(context) = error else {
                return XCTFail("Expected dataCorrupted error, got \(error)")
            }
            XCTAssertTrue(context.debugDescription.contains("Invalid legacy card updatedAt"))
        }
    }

    @MainActor
    func testRunIfNeededMarksCompleteAfterSuccessfulImport() throws {
        let (defaults, suiteName) = makeMigrationDefaults()
        let context = try makeInMemoryContext()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacyURL = directory.appendingPathComponent("cards.json")
        let backupURL = directory.appendingPathComponent("cards.json.migrated")
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """
        try json.data(using: .utf8)!.write(to: legacyURL)
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: suiteName)
        }

        MigrationService.runIfNeeded(
            context: context,
            legacyCardsURL: legacyURL,
            fileHandler: DefaultLegacyCardFileHandling(),
            userDefaults: defaults
        )

        let cards = try context.fetch(FetchDescriptor<CardModel>())
        XCTAssertEqual(cards.count, 1)
        XCTAssertTrue(defaults.bool(forKey: "cunningPaper.migration.v1.complete"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
    }

    @MainActor
    func testRunIfNeededPreservesExistingBackupByChoosingSuffix() throws {
        let (defaults, suiteName) = makeMigrationDefaults()
        let context = try makeInMemoryContext()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacyURL = directory.appendingPathComponent("cards.json")
        let existingBackupURL = directory.appendingPathComponent("cards.json.migrated")
        let suffixedBackupURL = directory.appendingPathComponent("cards.json.migrated-1")
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """
        try "previous backup".data(using: .utf8)!.write(to: existingBackupURL)
        try json.data(using: .utf8)!.write(to: legacyURL)
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: suiteName)
        }

        MigrationService.runIfNeeded(
            context: context,
            legacyCardsURL: legacyURL,
            fileHandler: DefaultLegacyCardFileHandling(),
            userDefaults: defaults
        )

        let cards = try context.fetch(FetchDescriptor<CardModel>())
        XCTAssertEqual(cards.count, 1)
        XCTAssertTrue(defaults.bool(forKey: "cunningPaper.migration.v1.complete"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: existingBackupURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: suffixedBackupURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyURL.path))
    }

    @MainActor
    func testRunIfNeededDoesNotMarkCompleteWhenImportFails() throws {
        let (defaults, suiteName) = makeMigrationDefaults()
        let context = try makeInMemoryContext()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacyURL = directory.appendingPathComponent("cards.json")
        let json = """
        [{"id":"not-a-uuid","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """
        try json.data(using: .utf8)!.write(to: legacyURL)
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: suiteName)
        }

        MigrationService.runIfNeeded(
            context: context,
            legacyCardsURL: legacyURL,
            fileHandler: DefaultLegacyCardFileHandling(),
            userDefaults: defaults
        )

        let cards = try context.fetch(FetchDescriptor<CardModel>())
        XCTAssertTrue(cards.isEmpty)
        XCTAssertFalse(defaults.bool(forKey: "cunningPaper.migration.v1.complete"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacyURL.path))
    }

    @MainActor
    func testRunIfNeededRollsBackImportedCardsWhenBackupMoveFails() throws {
        let (defaults, suiteName) = makeMigrationDefaults()
        let context = try makeInMemoryContext()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let legacyURL = directory.appendingPathComponent("cards.json")
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """
        try json.data(using: .utf8)!.write(to: legacyURL)
        defer {
            try? FileManager.default.removeItem(at: directory)
            defaults.removePersistentDomain(forName: suiteName)
        }

        let handler = FailingBackupMoveFileHandler()
        MigrationService.runIfNeeded(
            context: context,
            legacyCardsURL: legacyURL,
            fileHandler: handler,
            userDefaults: defaults
        )

        let cards = try context.fetch(FetchDescriptor<CardModel>())
        XCTAssertTrue(cards.isEmpty)
        XCTAssertFalse(defaults.bool(forKey: "cunningPaper.migration.v1.complete"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacyURL.path))
        XCTAssertEqual(handler.moveItemCallCount, 1)
    }

    func testLegacyCardsPathReturnsApplicationSupportLocation() {
        XCTAssertTrue(MigrationService.legacyCardsPath()?.path.contains("lens-note") == true)
    }

    func testNeedsMigrationFalseWhenAlreadyDone() {
        let suiteName = "MigrationServiceTests.needsMigration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "cunningPaper.migration.v1.complete")
        XCTAssertFalse(MigrationService.needsMigration(userDefaults: defaults))
    }

    private func makeMigrationDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "MigrationServiceTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: CardModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private final class FailingBackupMoveFileHandler: LegacyCardFileHandling {
        private let fileManager = FileManager.default
        private(set) var moveItemCallCount = 0

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
            moveItemCallCount += 1
            throw CocoaError(.fileWriteUnknown)
        }
    }
}
