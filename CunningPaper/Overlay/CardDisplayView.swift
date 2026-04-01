import SwiftUI

struct CardDisplayView: View {
    let title: String
    let paragraphs: [String]
    let activeIndex: Int
    let fontSize: Double
    let highlightCurrentParagraph: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: fontSize * 0.62, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                Text(paragraph)
                    .font(.system(size: fontSize))
                    .foregroundStyle(foregroundColor(for: index))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func foregroundColor(for index: Int) -> Color {
        guard highlightCurrentParagraph else { return .white }
        return index == activeIndex ? .white : .white.opacity(0.38)
    }
}
