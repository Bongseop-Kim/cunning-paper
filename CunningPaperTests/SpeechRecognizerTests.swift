import XCTest
@testable import CunningPaper

final class SpeechRecognizerTests: XCTestCase {

    func testNormalizeStripsNonAlphanumeric() {
        let result = SpeechRecognizer.normalize("Hello, World! 123")
        XCTAssertEqual(result, "hello world 123")
    }

    func testNormalizePreservesWhitespace() {
        let result = SpeechRecognizer.normalize("안녕 하세요")
        XCTAssertEqual(result, "안녕 하세요")
    }

    func testFuzzyMatchExact() {
        let sr = SpeechRecognizer()
        XCTAssertTrue(sr.isFuzzyMatch("hello", "hello"))
    }

    func testFuzzyMatchPrefix() {
        let sr = SpeechRecognizer()
        XCTAssertTrue(sr.isFuzzyMatch("notch", "not"))
    }

    func testFuzzyMatchEditDistance1() {
        let sr = SpeechRecognizer()
        XCTAssertTrue(sr.isFuzzyMatch("the", "thee"))
    }

    func testFuzzyMatchFails() {
        let sr = SpeechRecognizer()
        XCTAssertFalse(sr.isFuzzyMatch("apple", "orange"))
    }

    func testCharLevelMatchExact() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "hello world")
        let result = sr.charLevelMatch(spoken: "hello world")
        XCTAssertEqual(result, 11)
    }

    func testCharLevelMatchPartial() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "hello world")
        let result = sr.charLevelMatch(spoken: "hello")
        XCTAssertGreaterThan(result, 0)
        XCTAssertLessThanOrEqual(result, 11)
    }

    func testWordLevelMatchExact() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "hello world")
        let result = sr.wordLevelMatch(spoken: "hello world")
        XCTAssertEqual(result, 11)
    }

    func testWordLevelMatchSkipsAnnotation() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "[pause] hello world")
        let result = sr.wordLevelMatch(spoken: "hello world")
        XCTAssertGreaterThan(result, 0)
    }
}
