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
        engine.simulateActive(text: "hello world", charCount: 5)
        engine.stop()
        XCTAssertFalse(engine.isActive)
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }

    func testManualAdvanceParagraph() {
        let engine = ReadingEngine()
        engine.simulateManual(paragraphOffsets: [0, 12], total: "Hello world Goodbye world")
        engine.advanceParagraph()
        XCTAssertEqual(engine.highlightedCharCount, 12)
    }

    func testManualRetractParagraph() {
        let engine = ReadingEngine()
        engine.simulateManual(paragraphOffsets: [0, 12], total: "Hello world Goodbye world")
        engine.advanceParagraph()
        engine.retractParagraph()
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }

    func testAutoScrollIncreasesCharCount() {
        let engine = ReadingEngine()
        engine.simulateAutoScroll(text: "hello world this is a test")

        let expectation = XCTestExpectation(description: "charCount increases")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertGreaterThan(engine.highlightedCharCount, 0)
            engine.stop()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
