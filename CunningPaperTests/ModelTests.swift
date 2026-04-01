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

    func testCardModelWhitespaceOnlyBodyIsEmpty() {
        let card = CardModel(title: "T", body: "   \n\t  ")
        XCTAssertEqual(card.paragraphs, [])
        XCTAssertEqual(card.previewLine, "Empty card")
        XCTAssertEqual(card.paragraphCount, 0)
    }

    func testCardModelPreviewLineUsesFirstParagraph() {
        let card = CardModel(title: "T", body: "first line\nsecond line")
        XCTAssertEqual(card.previewLine, "first line")
    }

    func testCardModelPreviewLineFallsBackWhenBodyEmpty() {
        let card = CardModel(title: "T", body: "")
        XCTAssertEqual(card.previewLine, "Empty card")
    }

    func testCardModelParagraphCountMatchesParagraphs() {
        let card = CardModel(title: "T", body: "one\n\ntwo")
        XCTAssertEqual(card.paragraphCount, 2)
    }

    func testParagraphFocusReturnsFirstParagraphForLeadingSelection() {
        let text = "First line\n\nSecond line\nThird line"
        let index = ParagraphFocus.activeParagraphIndex(in: text, selectedRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(index, 0)
    }

    func testParagraphFocusReturnsMiddleParagraphForCaretInsideParagraph() {
        let text = "First line\n\nSecond line\nThird line"
        let location = (text as NSString).range(of: "Second").location
        let index = ParagraphFocus.activeParagraphIndex(in: text, selectedRange: NSRange(location: location, length: 0))
        XCTAssertEqual(index, 1)
    }

    func testParagraphFocusReturnsLastParagraphForEndOfTextSelection() {
        let text = "First line\n\nSecond line\nThird line"
        let index = ParagraphFocus.activeParagraphIndex(in: text, selectedRange: NSRange(location: (text as NSString).length, length: 0))
        XCTAssertEqual(index, 2)
    }

    func testParagraphFocusPreviewWindowCentersOnActiveParagraph() {
        let paragraphs = ["One", "Two", "Three", "Four"]
        XCTAssertEqual(ParagraphFocus.previewWindowParagraphs(in: paragraphs, activeIndex: 2), ["Two", "Three", "Four"])
    }

    func testParagraphFocusPreviewWindowFallsBackToLeadingParagraphs() {
        let paragraphs = ["One", "Two", "Three", "Four"]
        XCTAssertEqual(ParagraphFocus.previewWindowParagraphs(in: paragraphs, activeIndex: nil), ["One", "Two", "Three"])
    }

    func testParagraphFocusPreviewOpacitiesHighlightCenterParagraph() {
        XCTAssertEqual(ParagraphFocus.previewWindowOpacities(count: 3, activeSlot: 1), [0.35, 1.0, 0.55])
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
