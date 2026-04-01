import XCTest
@testable import CunningPaper

final class ModelTests: XCTestCase {
    func testCardModelParagraphsSplitsOnNewline() {
        let card = CardModel(title: "T", body: "line1\nline2\n\nline3")
        XCTAssertEqual(card.paragraphs, ["line1", "line2", "line3"])
    }

    func testCardModelParagraphsEmptyBody() {
        let card = CardModel(title: "T", body: "")
        XCTAssertEqual(card.paragraphs, [])
    }

    func testPrefsModelHotkeysRoundtrip() {
        let prefs = PrefsModel()
        var hotkeys = prefs.hotkeys
        hotkeys.next = "command+right"
        prefs.hotkeys = hotkeys
        XCTAssertEqual(prefs.hotkeys.next, "command+right")
    }

    func testPrefsModelCustomPresetsRoundtrip() {
        let prefs = PrefsModel()
        let preset = ZonePreset(id: "test", label: "Test", x: 0, y: 0, w: 0.5, h: 0.5, builtIn: false)
        prefs.customPresets = [preset]
        XCTAssertEqual(prefs.customPresets.first?.id, "test")
    }
}
