import XCTest
@testable import CunningPaper

final class GridMathTests: XCTestCase {
    func testCalcGridDimensionsLandscape1920x1080() {
        let dims = GridMath.calcGridDimensions(monitorW: 1920, monitorH: 1080)
        XCTAssertGreaterThan(dims.cols, dims.rows)
    }

    func testCalcGridDimensionsZeroReturnsMinimum() {
        let dims = GridMath.calcGridDimensions(monitorW: 0, monitorH: 0)
        XCTAssertEqual(dims.cols, 4)
        XCTAssertEqual(dims.rows, 4)
    }

    func testPointToCellCenter() {
        let cell = GridMath.pointToCell(x: 210, y: 210, cols: 4, rows: 4, canvasW: 420, canvasH: 420)
        XCTAssertEqual(cell.col, 2)
        XCTAssertEqual(cell.row, 2)
    }

    func testCellRangeToDisplayRectSingleCell() {
        let rect = GridMath.cellRangeToDisplayRect(c1: 0, r1: 0, c2: 0, r2: 0, cols: 4, rows: 4, canvasW: 400, canvasH: 400)
        XCTAssertEqual(rect.x, 0)
        XCTAssertEqual(rect.y, 0)
        XCTAssertEqual(rect.w, 100)
        XCTAssertEqual(rect.h, 100)
    }

    func testSnapGuideColumnsIncludesHalf() {
        let guides = GridMath.snapGuideColumns(count: 8)
        XCTAssertEqual(guides[1].label, "½")
    }
}
