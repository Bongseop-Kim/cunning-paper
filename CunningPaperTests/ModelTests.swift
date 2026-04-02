import AppKit
import SwiftUI
import XCTest
@testable import CunningPaper

final class ModelTests: XCTestCase {
    func testCardModelParagraphsSplitsOnNewline() {
        let card = CardModel(body: "line1\nline2\n\nline3")
        XCTAssertEqual(card.paragraphs, ["line1", "line2", "line3"])
    }

    func testCardModelParagraphsEmptyBody() {
        let card = CardModel(body: "")
        XCTAssertEqual(card.paragraphs, [])
    }

    func testCardModelWhitespaceOnlyBodyIsEmpty() {
        let card = CardModel(body: "   \n\t  ")
        XCTAssertEqual(card.paragraphs, [])
        XCTAssertEqual(card.listSubheadline, "Empty card")
        XCTAssertEqual(card.listHeadline, "Empty")
        XCTAssertEqual(card.paragraphCount, 0)
    }

    func testCardModelListHeadlineUsesFirstWord() {
        let card = CardModel(body: "first line\nsecond line")
        XCTAssertEqual(card.listHeadline, "first")
    }

    func testCardModelListHeadlineFallsBackWhenBodyEmpty() {
        let card = CardModel(body: "")
        XCTAssertEqual(card.listHeadline, "Empty")
    }

    func testCardModelListSubheadlineUsesFirstLine() {
        let card = CardModel(body: "first line\nsecond line")
        XCTAssertEqual(card.listSubheadline, "first line")
    }

    func testCardModelListSubheadlineFallsBackWhenBodyEmpty() {
        let card = CardModel(body: "")
        XCTAssertEqual(card.listSubheadline, "Empty card")
    }

    func testCardModelParagraphCountMatchesParagraphs() {
        let card = CardModel(body: "one\n\ntwo")
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

    func testParagraphFocusReturnsPreviousParagraphForBlankLineBetweenParagraphs() {
        let text = "First line\n\nSecond line"
        let blankLineLocation = (text as NSString).range(of: "\n\n").location + 1
        let index = ParagraphFocus.activeParagraphIndex(in: text, selectedRange: NSRange(location: blankLineLocation, length: 0))
        XCTAssertEqual(index, 0)
    }

    func testParagraphFocusReturnsNextParagraphForLeadingBlankLine() {
        let text = "\nFirst line\nSecond line"
        let index = ParagraphFocus.activeParagraphIndex(in: text, selectedRange: NSRange(location: 0, length: 0))
        XCTAssertEqual(index, 0)
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

    func testTextSyncSelectionResetsForWholesaleReplacement() {
        let selection = CardBodyTextView.synchronizedSelectionRange(
            currentText: "Original document",
            newText: "Completely different document",
            currentSelection: NSRange(location: 8, length: 4)
        )

        XCTAssertEqual(selection, NSRange(location: 0, length: 0))
    }

    func testTextSyncSelectionPreservesRangeForIncrementalReplacement() {
        let selection = CardBodyTextView.synchronizedSelectionRange(
            currentText: "Hello",
            newText: "Hello world",
            currentSelection: NSRange(location: 5, length: 0)
        )

        XCTAssertEqual(selection, NSRange(location: 5, length: 0))
    }

    func testCardBodyTextViewResetsSelectionWhenDocumentChanges() {
        let firstDocumentID = UUID()
        let secondDocumentID = UUID()
        var reportedParagraph: Int?
        let coordinator = CardBodyTextView.Coordinator(
            text: .constant("Shared text"),
            documentID: firstDocumentID,
            onActiveParagraphChange: { reportedParagraph = $0 }
        )
        let textView = NSTextView()
        textView.string = "Shared text"
        textView.setSelectedRange(NSRange(location: 6, length: 0))

        coordinator.resetForDocumentChange(to: secondDocumentID, text: "Shared text", in: textView)

        XCTAssertEqual(textView.selectedRange(), NSRange(location: 0, length: 0))
        XCTAssertEqual(coordinator.lastSeenDocumentID, secondDocumentID)
        XCTAssertEqual(reportedParagraph, 0)
    }

    func testPrefsModelCustomPresetsRoundtrip() {
        let prefs = PrefsModel()
        let preset = ZonePreset(id: "test", label: "Test", x: 0, y: 0, w: 0.5, h: 0.5, builtIn: false)
        prefs.customPresets = [preset]
        XCTAssertEqual(prefs.customPresets.first?.id, "test")
    }

    func testHotkeyActionRemovesSearchAction() {
        XCTAssertEqual(
            Set(HotkeyAction.allCases.map(\.rawValue)),
            ["next", "prev", "jump", "nextLine", "prevLine", "toggle"]
        )
    }
}
