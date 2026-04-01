import SwiftUI

struct CardPreviewPane: View {
    let title: String
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
                title: title,
                paragraphs: previewWindowParagraphs,
                activeIndex: 0,
                fontSize: 20,
                highlightCurrentParagraph: false,
                stackSpacing: 10,
                titleScale: 0.58,
                titleOpacity: 0.68,
                paragraphLineSpacing: 20 * 0.16,
                horizontalPadding: 18,
                verticalPadding: 16,
                paragraphOpacities: previewParagraphOpacities
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(nsColor: NSColor(calibratedWhite: 0.14, alpha: 1)))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
