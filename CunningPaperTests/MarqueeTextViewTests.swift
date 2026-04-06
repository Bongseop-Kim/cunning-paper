import XCTest
@testable import CunningPaper

final class MarqueeTextViewTests: XCTestCase {

    func testVisibleLineRangeIncludesActiveLineBelowViewport() {
        let range = visibleLineRange(
            totalLines: 20,
            lineHeight: 40,
            scrollOffset: 0,
            viewportHeight: 160,
            buffer: 40,
            activeLineIndex: 12
        )

        XCTAssertTrue(range.contains(12))
    }

    func testVisibleLineRangeIncludesActiveLineAboveViewport() {
        let range = visibleLineRange(
            totalLines: 20,
            lineHeight: 40,
            scrollOffset: -400,
            viewportHeight: 160,
            buffer: 40,
            activeLineIndex: 1
        )

        XCTAssertTrue(range.contains(1))
    }
}
