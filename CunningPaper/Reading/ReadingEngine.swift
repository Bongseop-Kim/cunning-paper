import Foundation
import Observation

@Observable
final class ReadingEngine {
    private(set) var highlightedCharCount = 0
    private(set) var isActive = false
    private(set) var fullText = ""

    private var currentParagraphIndex = 0
    private var paragraphOffsets: [Int] = []
    private var scrollTimer: Timer?
    private let recognizerFactory: () -> any SpeechRecognizing
    private var speechRecognizer: (any SpeechRecognizing)?
    private var pollingTimer: Timer?
    private var fractionalChars: Double = 0

    init(recognizerFactory: @escaping () -> any SpeechRecognizing = { SpeechRecognizer() }) {
        self.recognizerFactory = recognizerFactory
    }

    func start(card: CardModel, mode: ReadingMode, speed: Double = 3.0, language: String = "ko-KR") {
        stop()

        let (text, offsets) = buildTextAndOffsets(from: card)
        fullText = text
        paragraphOffsets = offsets
        currentParagraphIndex = 0
        highlightedCharCount = 0

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isActive = false
            return
        }

        isActive = true

        switch mode {
        case .manual:
            break
        case .autoScroll:
            startAutoScroll(speed: speed)
        case .voiceTracking:
            startVoiceTracking(language: language)
        }
    }

    func stop() {
        isActive = false
        highlightedCharCount = 0
        scrollTimer?.invalidate()
        scrollTimer = nil
        pollingTimer?.invalidate()
        pollingTimer = nil
        fractionalChars = 0
        speechRecognizer?.stop()
        speechRecognizer = nil
    }

    func advanceParagraph() {
        guard isActive, !paragraphOffsets.isEmpty else { return }
        let nextIndex = min(currentParagraphIndex + 1, paragraphOffsets.count - 1)
        currentParagraphIndex = nextIndex
        highlightedCharCount = paragraphOffsets[nextIndex]
    }

    func retractParagraph() {
        guard isActive, !paragraphOffsets.isEmpty else { return }
        let previousIndex = max(currentParagraphIndex - 1, 0)
        currentParagraphIndex = previousIndex
        highlightedCharCount = paragraphOffsets[previousIndex]
    }

    private func startAutoScroll(speed: Double) {
        guard speed > 0, !fullText.isEmpty else {
            scrollTimer?.invalidate()
            scrollTimer = nil
            fractionalChars = 0
            highlightedCharCount = 0
            isActive = false
            return
        }

        let interval = 1.0 / 30.0
        fractionalChars = 0
        scrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, self.isActive else { return }
            self.fractionalChars += speed * interval
            if self.fractionalChars >= 1 {
                let advance = Int(self.fractionalChars)
                self.fractionalChars -= Double(advance)
                self.highlightedCharCount = min(self.highlightedCharCount + advance, self.fullText.count)
                if self.highlightedCharCount >= self.fullText.count {
                    self.stop()
                }
            }
        }
        RunLoop.main.add(scrollTimer!, forMode: .common)
    }

    private func startVoiceTracking(language: String) {
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            speechRecognizer?.stop()
            speechRecognizer = nil
            pollingTimer?.invalidate()
            pollingTimer = nil
            isActive = false
            return
        }

        let recognizer = recognizerFactory()
        speechRecognizer = recognizer
        guard recognizer.start(with: fullText, language: language) else {
            stop()
            return
        }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self, self.isActive, let recognizer = self.speechRecognizer else {
                timer.invalidate()
                return
            }

            if recognizer.isFailed || recognizer.lastError != nil {
                self.stop()
                timer.invalidate()
                return
            }

            if recognizer.recognizedCharCount > self.highlightedCharCount {
                self.highlightedCharCount = recognizer.recognizedCharCount
            }
            if self.highlightedCharCount >= self.fullText.count {
                self.stop()
                timer.invalidate()
            }
        }
        RunLoop.main.add(pollingTimer!, forMode: .common)
    }

    private func buildTextAndOffsets(from card: CardModel) -> (String, [Int]) {
        let paragraphs = card.paragraphs
        var offsets: [Int] = []
        var collapsedParagraphs: [String] = []
        var offset = 0

        for paragraph in paragraphs {
            offsets.append(offset)
            let collapsed = splitTextIntoWords(paragraph).joined(separator: " ")
            collapsedParagraphs.append(collapsed)
            offset += collapsed.count + 1
        }

        return (collapsedParagraphs.joined(separator: " "), offsets)
    }

    #if DEBUG
    func simulateActive(text: String, charCount: Int) {
        fullText = text
        highlightedCharCount = charCount
        isActive = true
    }

    func simulateManual(paragraphOffsets: [Int], total: String) {
        self.paragraphOffsets = paragraphOffsets
        fullText = total
        currentParagraphIndex = 0
        highlightedCharCount = 0
        isActive = true
    }

    func simulateAutoScroll(text: String) {
        fullText = text
        paragraphOffsets = [0]
        highlightedCharCount = 0
        isActive = true
        startAutoScroll(speed: 10.0)
    }
    #endif
}
