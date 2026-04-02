import XCTest
@testable import CunningPaper

final class ZonePickerMathTests: XCTestCase {
    private let monitor = MonitorInfo(name: "Test", width: 1920, height: 1080, x: 0, y: 0, scaleFactor: 2)

    func testPlacementCanvasSizeWidthCappedAtMaxWidth() {
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        XCTAssertLessThanOrEqual(canvas.width, ZonePickerMath.minimapDisplayWidth)
    }

    func testPhysicalBoundsToDisplayRectRoundtrip() {
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        let physical = PhysicalBounds(x: 480, y: 270, width: 960, height: 540)
        let display = ZonePickerMath.physicalBoundsToDisplayRect(bounds: physical, monitor: monitor, canvasWidth: canvas.width)
        let back = ZonePickerMath.displayRectToPhysicalBounds(rect: display, monitor: monitor, canvasWidth: canvas.width)
        XCTAssertEqual(back.x, physical.x, accuracy: 1)
        XCTAssertEqual(back.y, physical.y, accuracy: 1)
        XCTAssertEqual(back.width, physical.width, accuracy: 1)
        XCTAssertEqual(back.height, physical.height, accuracy: 1)
    }

    func testDisplayRectToPhysicalBoundsUsesTopAlignedDisplayCoordinates() {
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        let display = DisplayRect(x: 0, y: 0, w: canvas.width, h: canvas.height / 2)

        let physical = ZonePickerMath.displayRectToPhysicalBounds(
            rect: display,
            monitor: monitor,
            canvasWidth: canvas.width
        )

        XCTAssertEqual(physical.x, 0, accuracy: 1)
        XCTAssertEqual(physical.y, 540, accuracy: 1)
        XCTAssertEqual(physical.width, 1920, accuracy: 1)
        XCTAssertEqual(physical.height, 540, accuracy: 1)
    }

    func testPhysicalBoundsToDisplayRectConvertsBottomLeftOriginToTopLeftDisplayCoordinates() {
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        let physical = PhysicalBounds(x: 0, y: 540, width: 1920, height: 540)

        let display = ZonePickerMath.physicalBoundsToDisplayRect(
            bounds: physical,
            monitor: monitor,
            canvasWidth: canvas.width
        )

        XCTAssertEqual(display.x, 0, accuracy: 1)
        XCTAssertEqual(display.y, 0, accuracy: 1)
        XCTAssertEqual(display.w, canvas.width, accuracy: 1)
        XCTAssertEqual(display.h, canvas.height / 2, accuracy: 1)
    }

    func testClampDisplayRectClampsToCanvas() {
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        let oversized = DisplayRect(x: -10, y: -10, w: canvas.width + 100, h: canvas.height + 100)
        let clamped = ZonePickerMath.clamp(rect: oversized, canvasWidth: canvas.width, canvasHeight: canvas.height)
        XCTAssertEqual(clamped.x, 0)
        XCTAssertEqual(clamped.y, 0)
        XCTAssertEqual(clamped.w, canvas.width)
        XCTAssertEqual(clamped.h, canvas.height)
    }
}
