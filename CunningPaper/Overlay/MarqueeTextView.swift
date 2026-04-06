import AppKit
import SwiftUI

struct WordItem: Identifiable {
    let id: Int
    let word: String
    let charOffset: Int
    let isAnnotation: Bool
    let letterCount: Int
}

struct WordYPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]

    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct MarqueeTextView: View {
    let text: String
    let highlightedCharCount: Int
    var fontSize: Double = 18

    private var words: [String] {
        splitTextIntoWords(text)
    }

    var body: some View {
        SpeechScrollView(
            words: words,
            highlightedCharCount: highlightedCharCount,
            font: .systemFont(ofSize: fontSize, weight: .semibold)
        )
    }
}

struct SpeechScrollView: View {
    let words: [String]
    let highlightedCharCount: Int
    var font: NSFont = .systemFont(ofSize: 18, weight: .semibold)
    var highlightColor: Color = .white
    var cueColor: Color = .white
    var cueUnreadOpacity: Double = 0.2
    var cueReadOpacity: Double = 0.5

    @State private var scrollOffset: CGFloat = 0
    @State private var wordYPositions: [Int: CGFloat] = [:]
    @State private var containerHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            WordFlowLayout(
                words: words,
                highlightedCharCount: highlightedCharCount,
                font: font,
                highlightColor: highlightColor,
                cueColor: cueColor,
                cueUnreadOpacity: cueUnreadOpacity,
                cueReadOpacity: cueReadOpacity,
                containerWidth: geometry.size.width,
                scrollOffset: scrollOffset,
                viewportHeight: geometry.size.height
            )
            .onPreferenceChange(WordYPreferenceKey.self) { positions in
                let wasEmpty = wordYPositions.isEmpty
                wordYPositions = positions
                if wasEmpty && !positions.isEmpty {
                    recalculateCenter(containerHeight: containerHeight)
                }
            }
            .offset(y: scrollOffset)
            .animation(.easeOut(duration: 0.5), value: scrollOffset)
            .onChange(of: geometry.size.height) { _, newHeight in
                containerHeight = newHeight
                if highlightedCharCount == 0 {
                    let lineHeight = font.pointSize * 1.4
                    scrollOffset = newHeight * 0.5 - lineHeight * 0.5
                } else {
                    recalculateCenter(containerHeight: newHeight)
                }
            }
            .onChange(of: highlightedCharCount) { _, _ in
                recalculateCenter(containerHeight: containerHeight)
            }
            .onChange(of: words) { _, _ in
                let lineHeight = font.pointSize * 1.4
                scrollOffset = containerHeight * 0.5 - lineHeight * 0.5
                wordYPositions = [:]
            }
            .onAppear {
                containerHeight = geometry.size.height
                let lineHeight = font.pointSize * 1.4
                scrollOffset = containerHeight * 0.5 - lineHeight * 0.5
            }
        }
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.05),
                    .init(color: .white, location: 0.95),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func recalculateCenter(containerHeight: CGFloat) {
        let center = containerHeight * 0.5
        let wordIndex = activeWordIndex()
        if let wordY = wordYPositions[wordIndex] {
            let target = center - wordY
            if abs(scrollOffset - target) > 1 {
                scrollOffset = target
            }
        }
    }

    private func activeWordIndex() -> Int {
        var offset = 0
        for (index, word) in words.enumerated() {
            let end = offset + word.count
            if highlightedCharCount <= end {
                return index
            }
            offset = end + 1
        }
        return max(0, words.count - 1)
    }
}

struct WordFlowLayout: View {
    let words: [String]
    let highlightedCharCount: Int
    let font: NSFont
    var highlightColor: Color = .white
    var cueColor: Color = .white
    var cueUnreadOpacity: Double = 0.2
    var cueReadOpacity: Double = 0.5
    let containerWidth: CGFloat
    var scrollOffset: CGFloat = 0
    var viewportHeight: CGFloat = 0

    private var lineSpacing: CGFloat {
        let intrinsicHeight = font.ascender - font.descender + font.leading
        return intrinsicHeight / font.pointSize > 1.5 ? 2 : 8
    }

    private static var cacheKey = ""
    private static var cachedItems: [WordItem] = []
    private static var cachedLines: [[WordItem]] = []

    var body: some View {
        let (items, lines) = cachedLayout()
        let nextIndex = nextWordIndex(items: items)
        let totalLines = lines.count
        let lineHeight = ceil(font.ascender - font.descender + font.leading) + lineSpacing

        let canCull = viewportHeight > 0 && totalLines > 0
        let buffer: CGFloat = 400
        let startLine = canCull
            ? max(0, min(totalLines, Int(floor((-scrollOffset - buffer) / lineHeight))))
            : 0
        let endLine = canCull
            ? max(startLine, min(totalLines, Int(ceil((viewportHeight - scrollOffset + buffer) / lineHeight))))
            : totalLines

        return VStack(alignment: .leading, spacing: lineSpacing) {
            if startLine > 0 {
                Color.clear.frame(height: CGFloat(startLine) * lineHeight)
            }

            ForEach(startLine..<endLine, id: \.self) { lineIndex in
                HStack(spacing: 0) {
                    ForEach(lines[lineIndex], id: \.id) { item in
                        wordView(for: item, isNextWord: item.id == nextIndex)
                    }
                }
            }

            if endLine < totalLines {
                Color.clear.frame(height: CGFloat(totalLines - endLine) * lineHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coordinateSpace(name: "flowLayout")
    }

    private func cachedLayout() -> ([WordItem], [[WordItem]]) {
        let key = "\(words.count)|\(words.first ?? "")|\(words.last ?? "")|\(font.pointSize)|\(Int(containerWidth))"
        if key == Self.cacheKey {
            return (Self.cachedItems, Self.cachedLines)
        }

        let items = buildItems()
        let lines = buildLines(items: items)
        Self.cacheKey = key
        Self.cachedItems = items
        Self.cachedLines = lines
        return (items, lines)
    }

    private func nextWordIndex(items: [WordItem]) -> Int {
        for item in items where !item.isAnnotation {
            let charsIntoWord = highlightedCharCount - item.charOffset
            let litCount = max(0, min(item.word.count, charsIntoWord))
            if litCount < item.letterCount {
                return item.id
            }
        }
        return -1
    }

    private func wordView(for item: WordItem, isNextWord: Bool) -> some View {
        let charsIntoWord = highlightedCharCount - item.charOffset
        let litCount = max(0, min(item.word.count, charsIntoWord))
        let isFullyLit = litCount >= item.letterCount
        let isCurrentWord = isNextWord || (charsIntoWord >= 0 && !isFullyLit)

        if item.isAnnotation {
            let annotationColor = isFullyLit
                ? cueColor.opacity(cueReadOpacity)
                : cueColor.opacity(cueUnreadOpacity)
            return AnyView(
                Text(item.word + " ")
                    .font(Font(font).italic())
                    .foregroundStyle(annotationColor)
                    .background(yReporter(for: item.id))
            )
        }

        let dimColor = isCurrentWord ? highlightColor.opacity(0.6) : highlightColor
        let wordColor = isFullyLit ? highlightColor.opacity(0.3) : dimColor

        return AnyView(
            Text(item.word + " ")
                .font(Font(font))
                .foregroundStyle(wordColor)
                .underline(isCurrentWord, color: wordColor)
                .background(yReporter(for: item.id))
        )
    }

    private func yReporter(for id: Int) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: WordYPreferenceKey.self,
                value: [id: geometry.frame(in: .named("flowLayout")).midY]
            )
        }
    }

    private func buildItems() -> [WordItem] {
        var items: [WordItem] = []
        var offset = 0
        for (index, word) in words.enumerated() {
            items.append(
                WordItem(
                    id: index,
                    word: word,
                    charOffset: offset,
                    isAnnotation: isAnnotationWord(word),
                    letterCount: max(1, word.filter { $0.isLetter || $0.isNumber }.count)
                )
            )
            offset += word.count + 1
        }
        return items
    }

    private func buildLines(items: [WordItem]) -> [[WordItem]] {
        var lines: [[WordItem]] = [[]]
        var currentLineWidth: CGFloat = 0
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width

        for item in items {
            let wordWidth = (item.word as NSString).size(withAttributes: [.font: font]).width + spaceWidth
            if currentLineWidth + wordWidth > containerWidth && !lines[lines.count - 1].isEmpty {
                lines.append([])
                currentLineWidth = 0
            }
            lines[lines.count - 1].append(item)
            currentLineWidth += wordWidth
        }

        return lines
    }

}
