import XCTest
@testable import CunningPaper

final class ZonePickerPresentationTests: XCTestCase {
    func testPositionHeaderUsesIntrinsicPickerWidthForMultipleMonitors() {
        XCTAssertNil(PositionHeaderView.monitorPickerWidth(for: 2))
    }

    func testSummaryLabelMatchesBuiltInLeftHalf() {
        let label = ZonePickerPresentation.summaryLabel(
            for: DisplayRect(x: 0, y: 0, w: 200, h: 400),
            canvas: CGSize(width: 400, height: 400)
        )

        XCTAssertEqual(label, "Left Half")
    }

    func testSummaryLabelFallsBackToCustom() {
        let label = ZonePickerPresentation.summaryLabel(
            for: DisplayRect(x: 40, y: 40, w: 180, h: 220),
            canvas: CGSize(width: 400, height: 400)
        )

        XCTAssertEqual(label, "Custom")
    }

    func testCustomPresetsOnlyIncludeMatchingMonitor() {
        let monitor = MonitorInfo(name: "Studio", width: 2560, height: 1440, x: 0, y: 0, scaleFactor: 2)
        let presets = [
            ZonePreset(id: "all", label: "All", x: 0, y: 0, w: 1, h: 1, builtIn: false, monitorId: nil, monitorName: nil),
            ZonePreset(id: "studio", label: "Studio Right", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: monitor.id, monitorName: monitor.name),
            ZonePreset(id: "other", label: "Other", x: 0, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: "other-monitor", monitorName: "Other")
        ]

        let filtered = ZonePickerPresentation.customPresets(for: monitor, allPresets: presets)

        XCTAssertEqual(filtered.map(\.id), ["all", "studio"])
    }

    func testDisplayPresetsShowNewestSavedFirstBeforeBuiltIns() {
        let custom = [
            ZonePreset(id: "older", label: "Older", x: 0, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: nil, monitorName: nil),
            ZonePreset(id: "newer", label: "Newer", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: nil, monitorName: nil)
        ]

        let displayed = ZonePickerPresentation.displayPresets(customPresets: custom)

        XCTAssertEqual(displayed.prefix(2).map(\.id), ["newer", "older"])
        XCTAssertEqual(displayed.dropFirst(2).first?.id, "full")
    }

    func testQuickPresetPreviewUsesTopLayoutForWidePreviewArea() {
        let layout = ZonePickerPresentation.quickPresetPreviewLayout(
            availableWidth: 118,
            availableHeight: 72
        )

        XCTAssertEqual(layout, .topThumbnail)
    }

    func testQuickPresetPreviewUsesSideLayoutForTightPreviewArea() {
        let layout = ZonePickerPresentation.quickPresetPreviewLayout(
            availableWidth: 92,
            availableHeight: 72
        )

        XCTAssertEqual(layout, .sideIcon)
    }

    func testQuickPresetPreviewFrameUsesExpectedTopThumbnailSize() {
        let size = ZonePickerPresentation.quickPresetPreviewFrame(for: .topThumbnail)

        XCTAssertEqual(size.width, 56)
        XCTAssertEqual(size.height, 34)
    }

    func testQuickPresetPreviewFrameUsesExpectedSideIconSize() {
        let size = ZonePickerPresentation.quickPresetPreviewFrame(for: .sideIcon)

        XCTAssertEqual(size.width, 34)
        XCTAssertEqual(size.height, 26)
    }

    func testQuickPresetPreviewLayoutTreatsMinimumCardWidthAsTopThumbnail() {
        let layout = ZonePickerPresentation.quickPresetPreviewLayout(
            availableWidth: 110,
            availableHeight: 72
        )

        XCTAssertEqual(layout, .topThumbnail)
    }

    func testDisplayPresetsKeepsNewestCustomPresetAheadOfBuiltIns() {
        let custom = [
            ZonePreset(id: "older", label: "Older", x: 0, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: nil, monitorName: nil),
            ZonePreset(id: "newer", label: "Newer", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: nil, monitorName: nil)
        ]

        let displayed = ZonePickerPresentation.displayPresets(customPresets: custom)

        XCTAssertEqual(displayed.map(\.id), ["newer", "older", "full", "left", "right", "top", "bottom", "center"])
    }
}
