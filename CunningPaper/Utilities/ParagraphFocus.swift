import Foundation

enum ParagraphFocus {
    static func activeParagraphIndex(in text: String, selectedRange: NSRange) -> Int? {
        let paragraphs = filteredParagraphEntries(in: text)
        guard !paragraphs.isEmpty else { return nil }

        let textLength = (text as NSString).length
        let clampedLocation = max(0, min(selectedRange.location, textLength))
        let targetLocation = textLength > 0 && clampedLocation == textLength ? clampedLocation - 1 : clampedLocation

        for (index, entry) in paragraphs.enumerated() {
            if NSLocationInRange(targetLocation, entry.range) {
                return index
            }
        }

        return paragraphs.indices.last
    }

    static func previewWindowParagraphs(in paragraphs: [String], activeIndex: Int?, radius: Int = 1) -> [String] {
        guard !paragraphs.isEmpty else { return [] }
        guard let activeIndex else {
            return Array(paragraphs.prefix((radius * 2) + 1))
        }

        let safeIndex = min(max(activeIndex, 0), paragraphs.count - 1)
        let lowerBound = max(0, safeIndex - radius)
        let upperBound = min(paragraphs.count - 1, safeIndex + radius)
        return Array(paragraphs[lowerBound...upperBound])
    }

    static func previewWindowOpacities(count: Int, activeSlot: Int?) -> [Double] {
        guard count > 0 else { return [] }
        guard let activeSlot else {
            return Array(repeating: 1.0, count: count)
        }

        return (0..<count).map { index in
            switch index - activeSlot {
            case ..<0:
                return 0.35
            case 0:
                return 1.0
            default:
                return 0.55
            }
        }
    }

    static func activeSlot(totalParagraphs: Int, activeIndex: Int?, radius: Int = 1) -> Int? {
        guard totalParagraphs > 0, let activeIndex else { return nil }
        let safeIndex = min(max(activeIndex, 0), totalParagraphs - 1)
        let lowerBound = max(0, safeIndex - radius)
        return safeIndex - lowerBound
    }

    private static func filteredParagraphEntries(in text: String) -> [(text: String, range: NSRange)] {
        let nsText = text as NSString
        var results: [(text: String, range: NSRange)] = []
        var searchRange = NSRange(location: 0, length: nsText.length)

        while searchRange.length > 0 {
            let paragraphRange = nsText.paragraphRange(for: NSRange(location: searchRange.location, length: 0))
            let paragraphText = nsText.substring(with: paragraphRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !paragraphText.isEmpty {
                results.append((text: paragraphText, range: paragraphRange))
            }

            let nextLocation = paragraphRange.location + paragraphRange.length
            guard nextLocation < nsText.length else { break }
            searchRange = NSRange(location: nextLocation, length: nsText.length - nextLocation)
        }

        if nsText.length == 0 {
            return []
        }

        return results
    }
}
