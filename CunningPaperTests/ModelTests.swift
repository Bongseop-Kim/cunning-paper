import AppKit
import SwiftData
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

    func testCardDetailViewResetActiveParagraphReportsNil() {
        var reportedParagraph: Int? = 3

        CardDetailView.resetActiveParagraph(using: { reportedParagraph = $0 })

        XCTAssertNil(reportedParagraph)
    }

    func testCardDetailViewApplyTextChangeSkipsEqualValue() {
        let timestamp = Date(timeIntervalSinceReferenceDate: 1234)
        let card = CardModel(body: "Same text", updatedAt: timestamp)
        var saveCallCount = 0

        CardDetailView.applyTextChange(
            "Same text",
            for: \.body,
            on: card,
            save: { _ in
                saveCallCount += 1
            }
        )

        XCTAssertEqual(card.body, "Same text")
        XCTAssertEqual(card.updatedAt, timestamp)
        XCTAssertEqual(saveCallCount, 0)
    }

    func testCardDetailViewLogSafeSaveErrorDetailsUsesNSErrorIdentifiers() {
        let error = NSError(
            domain: "CardSaveDomain",
            code: 99,
            userInfo: [NSLocalizedDescriptionKey: "Detailed failure message"]
        )

        let details = CardDetailView.logSafeSaveErrorDetails(for: error)

        XCTAssertEqual(details.domain, "CardSaveDomain")
        XCTAssertEqual(details.code, 99)
        XCTAssertEqual(details.description, "Detailed failure message")
    }

    func testCardListViewHandleMutationSaveFailurePresentsErrorAndBeeps() {
        enum SampleError: Error { case failure }

        var rollbackCallCount = 0
        var presented: (error: Error, fallbackMessage: String)?
        var beepCallCount = 0

        CardListView.handleMutationSaveFailure(
            SampleError.failure,
            fallbackMessage: "The card could not be created.",
            rollback: { rollbackCallCount += 1 },
            presentError: { error, fallbackMessage in
                presented = (error, fallbackMessage)
            },
            playFailureSound: { beepCallCount += 1 }
        )

        XCTAssertEqual(rollbackCallCount, 1)
        XCTAssertEqual(presented?.fallbackMessage, "The card could not be created.")
        XCTAssertTrue(presented?.error is SampleError)
        XCTAssertEqual(beepCallCount, 1)
    }

    @MainActor
    func testCardListViewPersistReturnsFailureWhenSaveThrows() throws {
        enum SampleError: Error { case failure }

        let context = try makeInMemoryContext()
        let result = CardListView.persist(context) { _ in
            throw SampleError.failure
        }

        switch result {
        case .success:
            XCTFail("Expected save failure")
        case .failure(let error):
            XCTAssertTrue(error is SampleError)
        }
    }

    @MainActor
    func testCardListViewPerformIsolatedMutationPreservesUnsavedSharedChangesOnFailure() throws {
        enum SampleError: Error { case failure }

        let container = try makeInMemoryContainer()
        let sharedContext = ModelContext(container)
        let firstCard = CardModel(body: "First", order: 0)
        let secondCard = CardModel(body: "Second", order: 1)
        sharedContext.insert(firstCard)
        sharedContext.insert(secondCard)
        try sharedContext.save()

        firstCard.body = "Unsaved draft"

        let result = CardListView.performIsolatedMutation(in: container, mutate: { mutationContext in
            let cards = try mutationContext.fetch(FetchDescriptor<CardModel>())
            guard let cardToDelete = cards.first(where: { $0.id == secondCard.id }) else {
                XCTFail("Expected to find card to delete in isolated context")
                return
            }
            mutationContext.delete(cardToDelete)
        }, save: { _ in
            throw SampleError.failure
        })

        switch result {
        case .success:
            XCTFail("Expected isolated mutation failure")
        case .failure(let error):
            XCTAssertTrue(error is SampleError)
        }

        XCTAssertEqual(firstCard.body, "Unsaved draft")

        let cards = try sharedContext.fetch(FetchDescriptor<CardModel>())
        XCTAssertEqual(cards.count, 2)
        XCTAssertNotNil(cards.first(where: { $0.id == secondCard.id }))
    }

    @MainActor
    func testCardListViewDeleteCardThrowsWhenCardMissing() throws {
        let container = try makeInMemoryContainer()
        let cardID = UUID()

        let result = CardListView.performIsolatedMutation(in: container, mutate: { mutationContext in
            try CardListView.deleteCard(withID: cardID, in: mutationContext)
        })

        switch result {
        case .success:
            XCTFail("Expected delete failure when card is missing")
        case .failure(let error):
            guard case CardListView.MutationError.cardNotFound(let missingID) = error else {
                return XCTFail("Expected cardNotFound error, got \(error)")
            }
            XCTAssertEqual(missingID, cardID)
        }
    }

    func testPrefsModelCustomPresetsRoundtrip() {
        let prefs = PrefsModel()
        let preset = ZonePreset(id: "test", label: "Test", x: 0, y: 0, w: 0.5, h: 0.5, builtIn: false)
        prefs.customPresets = [preset]
        XCTAssertEqual(prefs.customPresets.first?.id, "test")
    }

    func testHotkeyActionRemovesSearchAction() {
        XCTAssertFalse(HotkeyAction.allCases.map(\.rawValue).contains("search"))
    }

    @MainActor
    private func makeInMemoryContext() throws -> ModelContext {
        ModelContext(try makeInMemoryContainer())
    }

    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: CardModel.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}
