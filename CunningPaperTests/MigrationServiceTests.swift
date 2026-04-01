import XCTest
@testable import CunningPaper

final class MigrationServiceTests: XCTestCase {
    func testParseCardsJSONReturnsCards() throws {
        let json = """
        [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
        """

        let cards = try MigrationService.parseCardsJSON(Data(json.utf8))
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].title, "Intro")
        XCTAssertEqual(cards[0].body, "Hello")
    }

    func testParseCardsJSONEmptyArray() throws {
        let cards = try MigrationService.parseCardsJSON(Data("[]".utf8))
        XCTAssertTrue(cards.isEmpty)
    }

    func testLegacyCardsPathReturnsApplicationSupportLocation() {
        XCTAssertTrue(MigrationService.legacyCardsPath()?.path.contains("lens-note") == true)
    }

    func testNeedsMigrationFalseWhenAlreadyDone() {
        UserDefaults.standard.set(true, forKey: "cunningPaper.migration.v1.complete")
        XCTAssertFalse(MigrationService.needsMigration())
        UserDefaults.standard.removeObject(forKey: "cunningPaper.migration.v1.complete")
    }
}
