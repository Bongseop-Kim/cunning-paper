import AppKit
import SwiftUI

struct GridCanvasView: View {
    let monitor: MonitorInfo
    let canvas: (width: CGFloat, height: CGFloat, scale: CGFloat)
    let selection: DisplayRect?
    let onSelectionChange: (DisplayRect) -> Void
    let onSelectionCommit: (DisplayRect) -> Void

    @State private var dragStart: (col: Int, row: Int)?
    @State private var dragCurrent: (col: Int, row: Int)?

    private let guideBand: CGFloat = 24

    private var dimensions: (cols: Int, rows: Int) {
        GridMath.calcGridDimensions(monitorW: monitor.width, monitorH: monitor.height)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            guideLabels
            grid
                .offset(x: guideBand, y: guideBand)
        }
        .frame(width: canvas.width + guideBand, height: canvas.height + guideBand)
    }

    private var guideLabels: some View {
        let dims = dimensions
        let cellWidth = canvas.width / CGFloat(dims.cols)
        let cellHeight = canvas.height / CGFloat(dims.rows)

        return ZStack(alignment: .topLeading) {
            ForEach(GridMath.snapGuideColumns(count: dims.cols), id: \.index) { guide in
                Text(guide.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .position(x: guideBand + (CGFloat(guide.index) * cellWidth), y: guideBand / 2)
            }

            ForEach(GridMath.snapGuideRows(count: dims.rows), id: \.index) { guide in
                Text(guide.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .position(x: guideBand / 2, y: guideBand + (CGFloat(guide.index) * cellHeight))
            }
        }
    }

    private var grid: some View {
        let dims = dimensions
        let cellWidth = canvas.width / CGFloat(dims.cols)
        let cellHeight = canvas.height / CGFloat(dims.rows)
        let selectedRange = activeCellRange(
            cols: dims.cols,
            rows: dims.rows,
            cellWidth: cellWidth,
            cellHeight: cellHeight
        )

        return Canvas { context, _ in
            for row in 0..<dims.rows {
                for col in 0..<dims.cols {
                    let isSelected =
                        selectedRange.0 >= 0 &&
                        col >= selectedRange.0 &&
                        col <= selectedRange.2 &&
                        row >= selectedRange.1 &&
                        row <= selectedRange.3

                    let rect = CGRect(
                        x: (CGFloat(col) * cellWidth) + 1,
                        y: (CGFloat(row) * cellHeight) + 1,
                        width: max(cellWidth - 2, 1),
                        height: max(cellHeight - 2, 1)
                    )
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(isSelected ? Color.accentColor.opacity(0.9) : Color(nsColor: .quaternaryLabelColor))
                    )

                    if isSelected {
                        context.stroke(
                            Path(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 2),
                            with: .color(.white.opacity(0.9)),
                            lineWidth: 1
                        )
                    }
                }
            }
        }
        .frame(width: canvas.width, height: canvas.height)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let start = GridMath.pointToCell(
                        x: value.startLocation.x,
                        y: value.startLocation.y,
                        cols: dims.cols,
                        rows: dims.rows,
                        canvasW: canvas.width,
                        canvasH: canvas.height
                    )
                    let current = GridMath.pointToCell(
                        x: value.location.x,
                        y: value.location.y,
                        cols: dims.cols,
                        rows: dims.rows,
                        canvasW: canvas.width,
                        canvasH: canvas.height
                    )
                    dragStart = dragStart ?? start
                    dragCurrent = current
                    onSelectionChange(
                        GridMath.cellRangeToDisplayRect(
                            c1: start.col,
                            r1: start.row,
                            c2: current.col,
                            r2: current.row,
                            cols: dims.cols,
                            rows: dims.rows,
                            canvasW: canvas.width,
                            canvasH: canvas.height
                        )
                    )
                }
                .onEnded { value in
                    let start = dragStart ?? (0, 0)
                    let end = GridMath.pointToCell(
                        x: value.location.x,
                        y: value.location.y,
                        cols: dims.cols,
                        rows: dims.rows,
                        canvasW: canvas.width,
                        canvasH: canvas.height
                    )
                    let rect = GridMath.cellRangeToDisplayRect(
                        c1: start.0,
                        r1: start.1,
                        c2: end.col,
                        r2: end.row,
                        cols: dims.cols,
                        rows: dims.rows,
                        canvasW: canvas.width,
                        canvasH: canvas.height
                    )
                    dragStart = nil
                    dragCurrent = nil
                    onSelectionCommit(rect)
                }
        )
    }

    private func activeCellRange(
        cols: Int,
        rows: Int,
        cellWidth: CGFloat,
        cellHeight: CGFloat
    ) -> (Int, Int, Int, Int) {
        if let dragStart, let dragCurrent {
            return (
                min(dragStart.col, dragCurrent.col),
                min(dragStart.row, dragCurrent.row),
                max(dragStart.col, dragCurrent.col),
                max(dragStart.row, dragCurrent.row)
            )
        }

        guard let selection, selection.w > 0, selection.h > 0 else {
            return (-1, -1, -1, -1)
        }

        let c1 = Int((selection.x / cellWidth).rounded())
        let r1 = Int((selection.y / cellHeight).rounded())
        let c2 = min(cols - 1, Int(((selection.x + selection.w) / cellWidth).rounded()) - 1)
        let r2 = min(rows - 1, Int(((selection.y + selection.h) / cellHeight).rounded()) - 1)
        return (c1, r1, max(c1, c2), max(r1, r2))
    }
}
