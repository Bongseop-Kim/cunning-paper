import AVFoundation
import AppKit
import Foundation
import Observation
import Speech

@Observable
final class SpeechRecognizer {
    var recognizedCharCount: Int = 0
    var isListening: Bool = false
    var error: String?

    private(set) var sourceText: String = ""
    private(set) var matchStartOffset: Int = 0

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var retryCount = 0
    private let maxRetries = 10
    private var pendingRestart: DispatchWorkItem?
    private var sessionGeneration = 0
    private var language = "ko-KR"

    func start(with text: String, language: String = "ko-KR") {
        cleanupRecognition()
        self.language = language
        sourceText = splitTextIntoWords(text).joined(separator: " ")
        recognizedCharCount = 0
        matchStartOffset = 0
        retryCount = 0
        error = nil
        sessionGeneration += 1
        requestPermissionsAndBegin()
    }

    func stop() {
        isListening = false
        cleanupRecognition()
    }

    func prepareForTesting(text: String) {
        sourceText = splitTextIntoWords(text).joined(separator: " ")
        matchStartOffset = 0
        recognizedCharCount = 0
    }

    private func requestPermissionsAndBegin() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .denied, .restricted:
            error = "Microphone access denied. Enable in System Settings -> Privacy & Security -> Microphone."
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.requestSpeechAuthAndBegin()
                    } else {
                        self?.error = "Microphone access denied."
                    }
                }
            }
            return
        case .authorized:
            break
        @unknown default:
            break
        }

        requestSpeechAuthAndBegin()
    }

    private func requestSpeechAuthAndBegin() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.beginRecognition()
                } else {
                    self?.error = "Speech recognition not authorized. Enable in System Settings -> Privacy & Security -> Speech Recognition."
                }
            }
        }
    }

    private func cleanupRecognition() {
        pendingRestart?.cancel()
        pendingRestart = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func scheduleBeginRecognition(after delay: TimeInterval) {
        pendingRestart?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.pendingRestart = nil
            self?.beginRecognition()
        }
        pendingRestart = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func beginRecognition() {
        cleanupRecognition()
        audioEngine = AVAudioEngine()

        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            error = "Speech recognizer not available for language: \(language)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            if retryCount < maxRetries {
                retryCount += 1
                scheduleBeginRecognition(after: 0.5)
            } else {
                error = "Audio input unavailable"
                isListening = false
            }
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        let currentGeneration = sessionGeneration
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let spoken = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    guard self.sessionGeneration == currentGeneration else { return }
                    self.retryCount = 0
                    self.matchCharacters(spoken: spoken)
                }
            }

            if error != nil {
                DispatchQueue.main.async {
                    guard self.recognitionRequest != nil else { return }
                    if self.isListening && !self.sourceText.isEmpty && self.retryCount < self.maxRetries {
                        self.retryCount += 1
                        let delay = min(Double(self.retryCount) * 0.5, 1.5)
                        self.scheduleBeginRecognition(after: delay)
                    } else {
                        self.isListening = false
                    }
                }
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
        } catch {
            if retryCount < maxRetries {
                retryCount += 1
                scheduleBeginRecognition(after: 0.5)
            } else {
                self.error = "Audio engine failed: \(error.localizedDescription)"
                isListening = false
            }
        }
    }

    /// Internal matching helper kept visible for tests via `@testable import`.
    func matchCharacters(spoken: String) {
        let charResult = charLevelMatch(spoken: spoken)
        let wordResult = wordLevelMatch(spoken: spoken)
        let best = max(charResult, wordResult)
        let newCount = matchStartOffset + best
        if newCount > recognizedCharCount {
            recognizedCharCount = min(newCount, sourceText.count)
        }
    }

    /// Internal matching helper kept visible for tests via `@testable import`.
    func charLevelMatch(spoken: String) -> Int {
        let remainingSource = String(sourceText.dropFirst(matchStartOffset))
        let sourceCharacters = Array(remainingSource.lowercased().unicodeScalars).map(Character.init)
        let spokenCharacters = Array(Self.normalize(spoken).unicodeScalars).map(Character.init)

        var sourceIndex = 0
        var spokenIndex = 0
        var lastGoodOriginalIndex = 0

        while sourceIndex < sourceCharacters.count && spokenIndex < spokenCharacters.count {
            let sourceCharacter = sourceCharacters[sourceIndex]
            let spokenCharacter = spokenCharacters[spokenIndex]

            if !sourceCharacter.isLetter && !sourceCharacter.isNumber {
                sourceIndex += 1
                continue
            }
            if !spokenCharacter.isLetter && !spokenCharacter.isNumber {
                spokenIndex += 1
                continue
            }

            if sourceCharacter == spokenCharacter {
                sourceIndex += 1
                spokenIndex += 1
                lastGoodOriginalIndex = sourceIndex
                continue
            }

            var found = false
            let maxSpokenSkip = min(3, spokenCharacters.count - spokenIndex - 1)
            if maxSpokenSkip >= 1 {
                for skip in 1...maxSpokenSkip where spokenCharacters[spokenIndex + skip] == sourceCharacter {
                    spokenIndex += skip
                    found = true
                    break
                }
            }
            if found { continue }

            let maxSourceSkip = min(3, sourceCharacters.count - sourceIndex - 1)
            if maxSourceSkip >= 1 {
                for skip in 1...maxSourceSkip where sourceCharacters[sourceIndex + skip] == spokenCharacter {
                    sourceIndex += skip
                    found = true
                    break
                }
            }
            if found { continue }

            sourceIndex += 1
            spokenIndex += 1
            lastGoodOriginalIndex = sourceIndex
        }

        return lastGoodOriginalIndex
    }

    /// Internal matching helper kept visible for tests via `@testable import`.
    func wordLevelMatch(spoken: String) -> Int {
        let remainingSource = String(sourceText.dropFirst(matchStartOffset))
        let sourceWords = remainingSource.split(separator: " ").map(String.init)
        let spokenWords = spoken.lowercased().split(separator: " ").map(String.init)

        var sourceIndex = 0
        var spokenIndex = 0
        var matchedCharacterCount = 0

        while sourceIndex < sourceWords.count && spokenIndex < spokenWords.count {
            if isAnnotationWord(sourceWords[sourceIndex]) {
                matchedCharacterCount += sourceWords[sourceIndex].count
                if sourceIndex < sourceWords.count - 1 {
                    matchedCharacterCount += 1
                }
                sourceIndex += 1
                continue
            }

            let sourceWord = sourceWords[sourceIndex].lowercased().filter { $0.isLetter || $0.isNumber }
            let spokenWord = spokenWords[spokenIndex].filter { $0.isLetter || $0.isNumber }

            if sourceWord == spokenWord || isFuzzyMatch(sourceWord, spokenWord) {
                matchedCharacterCount += sourceWords[sourceIndex].count
                if sourceIndex < sourceWords.count - 1 {
                    matchedCharacterCount += 1
                }
                sourceIndex += 1
                spokenIndex += 1
                continue
            }

            var foundSpoken = false
            let maxSpokenSkip = min(3, spokenWords.count - spokenIndex - 1)
            if maxSpokenSkip >= 1 {
                for skip in 1...maxSpokenSkip {
                    let nextSpoken = spokenWords[spokenIndex + skip].filter { $0.isLetter || $0.isNumber }
                    if sourceWord == nextSpoken || isFuzzyMatch(sourceWord, nextSpoken) {
                        spokenIndex += skip
                        foundSpoken = true
                        break
                    }
                }
            }
            if foundSpoken { continue }

            var foundSource = false
            let maxSourceSkip = min(3, sourceWords.count - sourceIndex - 1)
            if maxSourceSkip >= 1 {
                for skip in 1...maxSourceSkip {
                    let nextSource = sourceWords[sourceIndex + skip].lowercased().filter { $0.isLetter || $0.isNumber }
                    if nextSource == spokenWord || isFuzzyMatch(nextSource, spokenWord) {
                        for offset in 0..<skip {
                            matchedCharacterCount += sourceWords[sourceIndex + offset].count + 1
                        }
                        sourceIndex += skip
                        foundSource = true
                        break
                    }
                }
            }
            if foundSource { continue }

            if sourceWord.isEmpty {
                matchedCharacterCount += sourceWords[sourceIndex].count
                if sourceIndex < sourceWords.count - 1 {
                    matchedCharacterCount += 1
                }
                sourceIndex += 1
                continue
            }

            spokenIndex += 1
        }

        while sourceIndex < sourceWords.count && isAnnotationWord(sourceWords[sourceIndex]) {
            matchedCharacterCount += sourceWords[sourceIndex].count
            if sourceIndex < sourceWords.count - 1 {
                matchedCharacterCount += 1
            }
            sourceIndex += 1
        }

        return matchedCharacterCount
    }

    /// Internal matching helper kept visible for tests via `@testable import`.
    func isFuzzyMatch(_ a: String, _ b: String) -> Bool {
        if a.isEmpty || b.isEmpty { return false }
        if a == b { return true }
        if a.hasPrefix(b) || b.hasPrefix(a) { return true }
        if a.contains(b) || b.contains(a) { return true }

        let sharedPrefixCount = zip(a, b).prefix(while: ==).count
        let shorterLength = min(a.count, b.count)
        if shorterLength >= 2 && sharedPrefixCount >= max(2, shorterLength * 3 / 5) {
            return true
        }

        let distance = editDistance(a, b)
        if shorterLength <= 4 { return distance <= 1 }
        if shorterLength <= 8 { return distance <= 2 }
        return distance <= max(a.count, b.count) / 3
    }

    static func normalize(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
    }

    private func editDistance(_ a: String, _ b: String) -> Int {
        let sourceCharacters = Array(a)
        let targetCharacters = Array(b)
        var dp = Array(0...targetCharacters.count)

        for i in 1...sourceCharacters.count {
            var previous = dp[0]
            dp[0] = i
            for j in 1...targetCharacters.count {
                let current = dp[j]
                if sourceCharacters[i - 1] == targetCharacters[j - 1] {
                    dp[j] = previous
                } else {
                    dp[j] = min(previous, dp[j], dp[j - 1]) + 1
                }
                previous = current
            }
        }

        return dp[targetCharacters.count]
    }

}
