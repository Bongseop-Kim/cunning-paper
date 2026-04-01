import SwiftUI

struct CardDisplayView: View {
    let paragraphs: [String]
    let activeIndex: Int
    let fontSize: Double
    let highlightCurrentParagraph: Bool
    var stackSpacing: CGFloat = 8
    var paragraphLineSpacing: Double = 0
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 12
    var paragraphOpacities: [Double]? = nil
    var bottomFadeHeight: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: stackSpacing) {
                ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                    Text(paragraph)
                        .font(.system(size: fontSize))
                        .lineSpacing(paragraphLineSpacing)
                        .foregroundStyle(foregroundColor(for: index))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .mask(bottomFadeMask)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .clipped()
    }

    private func foregroundColor(for index: Int) -> Color {
        if let paragraphOpacities, paragraphOpacities.indices.contains(index) {
            return .white.opacity(paragraphOpacities[index])
        }
        guard highlightCurrentParagraph else { return .white }
        return index == activeIndex ? .white : .white.opacity(0.38)
    }

    private var bottomFadeMask: some View {
        GeometryReader { geometry in
            let height = max(geometry.size.height, 1)
            let fadeStart = max(height - bottomFadeHeight, 0)

            LinearGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: fadeStart / height),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
