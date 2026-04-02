import AppKit
import SwiftUI

enum CardPreviewMetrics {
    static let visibleParagraphCount = 3
    static let fontSize: CGFloat = 20
    static let stackSpacing: CGFloat = 10
    static let paragraphLineSpacing = fontSize * 0.16
    static let horizontalPadding: CGFloat = 18
    static let verticalPadding: CGFloat = 16
    private static let lineHeightLayoutManager = NSLayoutManager()

    static func cardHeight(forVisibleParagraphs count: Int) -> CGFloat {
        let visibleCount = max(count, 1)
        let lineHeight = lineHeightLayoutManager.defaultLineHeight(for: NSFont.systemFont(ofSize: fontSize))
        let paragraphHeights = lineHeight * CGFloat(visibleCount)
        let paragraphGaps = stackSpacing * CGFloat(max(visibleCount - 1, 0))
        return ceil(paragraphHeights + paragraphGaps + (verticalPadding * 2))
    }

    static var cardHeight: CGFloat {
        cardHeight(forVisibleParagraphs: visibleParagraphCount)
    }
}

struct CardPreviewPane: View {
    let paragraphs: [String]
    let activeParagraphIndex: Int?

    private var previewWindowParagraphs: [String] {
        let content = paragraphs.isEmpty ? ["Start writing to see the reading preview."] : paragraphs
        return ParagraphFocus.previewWindowParagraphs(in: content, activeIndex: activeParagraphIndex)
    }

    private var previewParagraphOpacities: [Double] {
        ParagraphFocus.previewWindowOpacities(
            count: previewWindowParagraphs.count,
            activeSlot: ParagraphFocus.activeSlot(totalParagraphs: max(paragraphs.count, 1), activeIndex: activeParagraphIndex)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            CardDisplayView(
                paragraphs: previewWindowParagraphs,
                activeIndex: 0,
                fontSize: CardPreviewMetrics.fontSize,
                highlightCurrentParagraph: false,
                stackSpacing: CardPreviewMetrics.stackSpacing,
                paragraphLineSpacing: CardPreviewMetrics.paragraphLineSpacing,
                horizontalPadding: CardPreviewMetrics.horizontalPadding,
                verticalPadding: CardPreviewMetrics.verticalPadding,
                paragraphOpacities: previewParagraphOpacities,
                paragraphLineLimit: 1
            )
            .frame(maxWidth: .infinity, minHeight: CardPreviewMetrics.cardHeight, maxHeight: CardPreviewMetrics.cardHeight, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(nsColor: NSColor(calibratedWhite: 0.14, alpha: 1)))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
