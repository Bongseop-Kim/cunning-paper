import XCTest
@testable import CunningPaper

final class ReadingEngineTests: XCTestCase {

    func testReadingModeAllCases() {
        XCTAssertEqual(ReadingMode.allCases.count, 3)
        XCTAssertTrue(ReadingMode.allCases.contains(.manual))
        XCTAssertTrue(ReadingMode.allCases.contains(.autoScroll))
        XCTAssertTrue(ReadingMode.allCases.contains(.voiceTracking))
    }

    func testHotkeyActionHasStop() {
        XCTAssertNotNil(HotkeyAction(rawValue: "stop"))
        XCTAssertEqual(HotkeyAction(rawValue: "stop"), .stop)
    }

    func testEngineInitialState() {
        let engine = ReadingEngine()
        XCTAssertFalse(engine.isActive)
        XCTAssertEqual(engine.highlightedCharCount, 0)
        XCTAssertEqual(engine.fullText, "")
    }

    func testEngineStopResetsState() {
        let engine = ReadingEngine()
        let card = CardModel(body: "hello world")
        engine.start(card: card, mode: .manual)
        engine.advanceParagraph()
        engine.stop()
        XCTAssertFalse(engine.isActive)
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }

    func testManualAdvanceParagraph() {
        let engine = ReadingEngine()
        let card = CardModel(body: "Hello world\nGoodbye world")
        engine.start(card: card, mode: .manual)
        engine.advanceParagraph()
        XCTAssertEqual(engine.highlightedCharCount, 12)
    }

    func testManualRetractParagraph() {
        let engine = ReadingEngine()
        let card = CardModel(body: "Hello world\nGoodbye world")
        engine.start(card: card, mode: .manual)
        engine.advanceParagraph()
        engine.retractParagraph()
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }

    func testAutoScrollIncreasesCharCount() {
        let engine = ReadingEngine()
        let card = CardModel(body: "hello world this is a test")
        engine.start(card: card, mode: .autoScroll, speed: 10)

        let expectation = XCTestExpectation(description: "charCount increases")
        let deadline = Date().addingTimeInterval(2.0)

        func poll() {
            if engine.highlightedCharCount > 0 {
                engine.stop()
                expectation.fulfill()
                return
            }

            if Date() >= deadline {
                engine.stop()
                XCTFail("Expected auto-scroll to advance highlighted characters before timeout.")
                expectation.fulfill()
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: poll)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: poll)

        wait(for: [expectation], timeout: 2.5)
    }

    func testAutoScrollWithInvalidSpeedDoesNotActivateEngine() {
        let engine = ReadingEngine()
        let card = CardModel(body: "hello world")

        engine.start(card: card, mode: .autoScroll, speed: 0)

        XCTAssertFalse(engine.isActive)
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }

    func testVoiceTrackingWithEmptyCardDoesNotActivateEngine() {
        let engine = ReadingEngine()
        let card = CardModel(body: "   \n  ")

        engine.start(card: card, mode: .voiceTracking, language: "ko-KR")

        XCTAssertFalse(engine.isActive)
        XCTAssertEqual(engine.fullText, "")
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }
}
