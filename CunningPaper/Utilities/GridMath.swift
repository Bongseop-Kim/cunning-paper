import Foundation

enum GridMath {
    private static let minGridSize = 4
    private static let targetCells = 160

    static func calcGridDimensions(monitorW: Int, monitorH: Int) -> (cols: Int, rows: Int) {
        guard monitorW > 0, monitorH > 0 else { return (minGridSize, minGridSize) }
        let ratio = Double(monitorW) / Double(monitorH)
        let cols = max(minGridSize, Int((Double(targetCells) * ratio).squareRoot().rounded()))
        let rows = max(minGridSize, Int((Double(targetCells) / Double(cols)).rounded()))
        return (cols, rows)
    }

    static func pointToCell(
        x: CGFloat,
        y: CGFloat,
        cols: Int,
        rows: Int,
        canvasW: CGFloat,
        canvasH: CGFloat
    ) -> (col: Int, row: Int) {
        guard cols > 0, rows > 0, canvasW > 0, canvasH > 0 else { return (0, 0) }
        let col = min(max(Int((x / canvasW) * CGFloat(cols)), 0), cols - 1)
        let row = min(max(Int((y / canvasH) * CGFloat(rows)), 0), rows - 1)
        return (col, row)
    }

    static func cellRangeToDisplayRect(
        c1: Int,
        r1: Int,
        c2: Int,
        r2: Int,
        cols: Int,
        rows: Int,
        canvasW: CGFloat,
        canvasH: CGFloat
    ) -> DisplayRect {
        guard cols > 0, rows > 0 else { return DisplayRect(x: 0, y: 0, w: 0, h: 0) }
        let startCol = min(c1, c2)
        let startRow = min(r1, r2)
        let endCol = max(c1, c2)
        let endRow = max(r1, r2)
        let cellWidth = canvasW / CGFloat(cols)
        let cellHeight = canvasH / CGFloat(rows)

        return DisplayRect(
            x: (CGFloat(startCol) * cellWidth).rounded(),
            y: (CGFloat(startRow) * cellHeight).rounded(),
            w: (CGFloat(endCol - startCol + 1) * cellWidth).rounded(),
            h: (CGFloat(endRow - startRow + 1) * cellHeight).rounded()
        )
    }

    static func presetRatioToDisplayRect(
        px: Double,
        py: Double,
        pw: Double,
        ph: Double,
        cols: Int,
        rows: Int,
        canvasW: CGFloat,
        canvasH: CGFloat
    ) -> DisplayRect {
        let c1 = max(0, Int((px * Double(cols)).rounded()))
        let r1 = max(0, Int((py * Double(rows)).rounded()))
        let c2 = max(c1, min(cols - 1, Int(((px + pw) * Double(cols)).rounded()) - 1))
        let r2 = max(r1, min(rows - 1, Int(((py + ph) * Double(rows)).rounded()) - 1))
        return cellRangeToDisplayRect(
            c1: c1,
            r1: r1,
            c2: c2,
            r2: r2,
            cols: cols,
            rows: rows,
            canvasW: canvasW,
            canvasH: canvasH
        )
    }

    static func displayRectToPresetRatio(
        rect: DisplayRect,
        cols: Int,
        rows: Int,
        canvasW: CGFloat,
        canvasH: CGFloat
    ) -> (x: Double, y: Double, w: Double, h: Double) {
        guard cols > 0, rows > 0 else { return (0, 0, 0, 0) }
        let cellWidth = canvasW / CGFloat(cols)
        let cellHeight = canvasH / CGFloat(rows)
        let c1 = max(0, Int((rect.x / cellWidth).rounded()))
        let r1 = max(0, Int((rect.y / cellHeight).rounded()))
        let c2 = max(c1, Int(((rect.x + rect.w) / cellWidth).rounded()))
        let r2 = max(r1, Int(((rect.y + rect.h) / cellHeight).rounded()))
        return (
            Double(c1) / Double(cols),
            Double(r1) / Double(rows),
            Double(c2 - c1) / Double(cols),
            Double(r2 - r1) / Double(rows)
        )
    }

    static func snapGuideColumns(count: Int) -> [(index: Int, label: String)] {
        buildGuides(count: count)
    }

    static func snapGuideRows(count: Int) -> [(index: Int, label: String)] {
        buildGuides(count: count)
    }

    private static func buildGuides(count: Int) -> [(index: Int, label: String)] {
        guard count > 0 else { return [] }
        return [(0.25, "¼"), (0.5, "½"), (0.75, "¾")].compactMap { fraction, label in
            let index = Int((fraction * Double(count)).rounded())
            guard index > 0, index < count else { return nil }
            return (index, label)
        }
    }
}
