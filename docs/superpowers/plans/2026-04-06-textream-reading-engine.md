# Textream Reading Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Textream의 Word Tracking, Auto-scroll, MarqueeTextView를 cunning-paper의 카드 기반 아키텍처에 통합한다.

**Architecture:** 새로운 `ReadingEngine` (@Observable) 이 모드·위치·음성인식을 전담한다. 세 모드(Manual/Auto-scroll/Voice Tracking) 모두 `ReadingEngine.highlightedCharCount` 단일 값만 업데이트하며, `MarqueeTextView`는 이 값을 보고 현재 단어를 중앙에 표시한다. `OverlayView`는 `CardDisplayView` 대신 `MarqueeTextView`를 사용하며, `AppCoordinator`의 hotkey 흐름(HotkeyManager → NotificationCenter → OverlayView)은 유지된다.

**Tech Stack:** Swift 5.0+, SwiftUI, SwiftData, Speech framework, AVFoundation, XCTest

---

## File Structure

### 신규 생성
- `CunningPaper/Reading/ReadingMode.swift` — ReadingMode enum
- `CunningPaper/Reading/ReadingEngine.swift` — 모드·위치·타이머 통합 관리
- `CunningPaper/Reading/SpeechRecognizer.swift` — Textream 이식, 퍼지 매칭
- `CunningPaper/Overlay/MarqueeTextView.swift` — Textream 이식, 단어 플로우+하이라이트
- `CunningPaperTests/ReadingEngineTests.swift` — ReadingEngine 단위 테스트
- `CunningPaperTests/SpeechRecognizerTests.swift` — 퍼지 매칭 단위 테스트

### 수정
- `CunningPaper/Data/PrefsModel.swift` — readingModeRaw, autoScrollSpeed, speechLanguage 추가
- `CunningPaper/System/HotkeyManager.swift` — .stop 액션 추가
- `CunningPaper/Overlay/OverlayView.swift` — CardDisplayView → MarqueeTextView 교체, ReadingEngine 연결
- `CunningPaper/Editor/Preferences/PreferencesView.swift` — 읽기 설정 섹션 추가

### Xcode 프로젝트 설정 (코드 외)
- `CunningPaper` 타겟 → Info 탭 → 두 키 추가:
  - `NSMicrophoneUsageDescription`: `"CunningPaper needs microphone access for voice tracking mode."`
  - `NSSpeechRecognitionUsageDescription`: `"CunningPaper uses on-device speech recognition to highlight words as you read."`

---

## Task 1: ReadingMode + PrefsModel + HotkeyManager

**Files:**
- Create: `CunningPaper/Reading/ReadingMode.swift`
- Modify: `CunningPaper/Data/PrefsModel.swift`
- Modify: `CunningPaper/System/HotkeyManager.swift`
- Test: `CunningPaperTests/ReadingEngineTests.swift` (초기 파일)

---

- [ ] **Step 1.1: 테스트 파일 생성 및 실패 확인**

`CunningPaperTests/ReadingEngineTests.swift`를 생성한다:

```swift
import XCTest
@testable import CunningPaper

final class ReadingEngineTests: XCTestCase {

    func testReadingModeAllCases() {
        XCTAssertEqual(ReadingMode.allCases.count, 3)
        XCTAssertTrue(ReadingMode.allCases.contains(.manual))
        XCTAssertTrue(ReadingMode.allCases.contains(.autoScroll))
        XCTAssertTrue(ReadingMode.allCases.contains(.voiceTracking))
    }

    func testHotkeyActionHasStop() {
        XCTAssertNotNil(HotkeyAction(rawValue: "stop"))
        XCTAssertEqual(HotkeyAction(rawValue: "stop"), .stop)
    }
}
```

- [ ] **Step 1.2: 테스트 실행 — 실패 확인**

Xcode에서 `CunningPaperTests` 타겟 빌드. `ReadingMode` 및 `HotkeyAction.stop` 미정의로 컴파일 오류 발생 확인.

- [ ] **Step 1.3: ReadingMode 생성**

`CunningPaper/Reading/ReadingMode.swift`:

```swift
import Foundation

enum ReadingMode: String, CaseIterable {
    case manual
    case autoScroll
    case voiceTracking
}
```

- [ ] **Step 1.4: PrefsModel에 읽기 설정 필드 추가**

`CunningPaper/Data/PrefsModel.swift`의 `@Model final class PrefsModel` 프로퍼티 블록에 추가:

```swift
// Reading settings
var readingModeRaw: String
var autoScrollSpeed: Double
var speechLanguage: String
```

`init()` 내부에 초기값 추가 (`customPresetsData` 초기화 다음 줄):

```swift
readingModeRaw = ReadingMode.voiceTracking.rawValue
autoScrollSpeed = 3.0
speechLanguage = "ko-KR"
```

`PrefsModel` 클래스 바디 끝에 computed property 추가:

```swift
var readingMode: ReadingMode {
    get { ReadingMode(rawValue: readingModeRaw) ?? .voiceTracking }
    set { readingModeRaw = newValue.rawValue }
}
```

- [ ] **Step 1.5: HotkeyManager에 stop 추가**

`CunningPaper/System/HotkeyManager.swift`의 `HotkeyAction` enum에 `.stop` 추가:

```swift
enum HotkeyAction: String, CaseIterable {
    case next
    case prev
    case jump
    case nextLine
    case prevLine
    case toggle
    case stop        // 읽기 정지
}
```

같은 파일의 `KeyboardShortcuts.Name` extension에 추가:

```swift
extension KeyboardShortcuts.Name {
    static let next = Self("cunningPaper.next")
    static let prev = Self("cunningPaper.prev")
    static let jump = Self("cunningPaper.jump")
    static let nextLine = Self("cunningPaper.nextLine")
    static let prevLine = Self("cunningPaper.prevLine")
    static let toggle = Self("cunningPaper.toggle")
    static let stop = Self("cunningPaper.stop")   // 추가
}
```

`HotkeyManager.init()` 내부, `register(.toggle, name: .toggle)` 다음 줄에 추가:

```swift
register(.stop, name: .stop)
```

- [ ] **Step 1.6: 테스트 실행 — 통과 확인**

`CunningPaperTests/ReadingEngineTests.swift`의 두 테스트가 모두 통과하는지 확인.

- [ ] **Step 1.7: 커밋**

```bash
git add CunningPaper/Reading/ReadingMode.swift \
        CunningPaper/Data/PrefsModel.swift \
        CunningPaper/System/HotkeyManager.swift \
        CunningPaperTests/ReadingEngineTests.swift
git commit -m "feat: add ReadingMode enum, PrefsModel reading fields, HotkeyManager stop action"
```

---

## Task 2: SpeechRecognizer

Textream의 `SpeechRecognizer.swift`에서 핵심 로직만 이식한다. 제거 항목: `AudioInputDevice`, `audioLevels`, `isSpeaking`, `lastSpokenText`, `shouldDismiss`, `shouldAdvancePage`, `updateText`, `jumpTo`, `forceStop`, `resume`, 마이크 디바이스 선택 코드, 설정 앱 열기 함수.

**Files:**
- Create: `CunningPaper/Reading/SpeechRecognizer.swift`
- Test: `CunningPaperTests/SpeechRecognizerTests.swift`

---

- [ ] **Step 2.1: 퍼지 매칭 테스트 파일 생성**

`CunningPaperTests/SpeechRecognizerTests.swift`:

```swift
import XCTest
@testable import CunningPaper

final class SpeechRecognizerTests: XCTestCase {

    // MARK: - normalize

    func testNormalizeStripsNonAlphanumeric() {
        let result = SpeechRecognizer.normalize("Hello, World! 123")
        XCTAssertEqual(result, "hello world 123")
    }

    func testNormalizePreservesWhitespace() {
        let result = SpeechRecognizer.normalize("안녕 하세요")
        XCTAssertEqual(result, "안녕 하세요")
    }

    // MARK: - isFuzzyMatch

    func testFuzzyMatchExact() {
        let sr = SpeechRecognizer()
        XCTAssertTrue(sr.isFuzzyMatch("hello", "hello"))
    }

    func testFuzzyMatchPrefix() {
        let sr = SpeechRecognizer()
        XCTAssertTrue(sr.isFuzzyMatch("notch", "not"))
    }

    func testFuzzyMatchEditDistance1() {
        let sr = SpeechRecognizer()
        XCTAssertTrue(sr.isFuzzyMatch("the", "thee"))
    }

    func testFuzzyMatchFails() {
        let sr = SpeechRecognizer()
        XCTAssertFalse(sr.isFuzzyMatch("apple", "orange"))
    }

    // MARK: - charLevelMatch

    func testCharLevelMatchExact() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "hello world")
        let result = sr.charLevelMatch(spoken: "hello world")
        XCTAssertEqual(result, 11)
    }

    func testCharLevelMatchPartial() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "hello world")
        let result = sr.charLevelMatch(spoken: "hello")
        XCTAssertGreaterThan(result, 0)
        XCTAssertLessThanOrEqual(result, 11)
    }

    // MARK: - wordLevelMatch

    func testWordLevelMatchExact() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "hello world")
        let result = sr.wordLevelMatch(spoken: "hello world")
        XCTAssertEqual(result, 11)
    }

    func testWordLevelMatchSkipsAnnotation() {
        let sr = SpeechRecognizer()
        sr.prepareForTesting(text: "[pause] hello world")
        let result = sr.wordLevelMatch(spoken: "hello world")
        XCTAssertGreaterThan(result, 0)
    }
}
```

- [ ] **Step 2.2: 테스트 실행 — 실패 확인**

`SpeechRecognizer` 미정의, `prepareForTesting` 미정의로 컴파일 오류 확인.

- [ ] **Step 2.3: SpeechRecognizer 파일 생성**

`CunningPaper/Reading/SpeechRecognizer.swift`:

```swift
import AppKit
import Foundation
import Speech
import AVFoundation

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
    private var retryCount: Int = 0
    private let maxRetries: Int = 10
    private var pendingRestart: DispatchWorkItem?
    private var sessionGeneration: Int = 0
    private var language: String = "ko-KR"

    // MARK: - Public API

    func start(with text: String, language: String = "ko-KR") {
        cleanupRecognition()
        self.language = language
        let words = splitTextIntoWords(text)
        let collapsed = words.joined(separator: " ")
        sourceText = collapsed
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

    /// Test helper: sets sourceText without triggering audio engine
    func prepareForTesting(text: String) {
        let words = splitTextIntoWords(text)
        sourceText = words.joined(separator: " ")
        matchStartOffset = 0
        recognizedCharCount = 0
    }

    // MARK: - Permissions

    private func requestPermissionsAndBegin() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .denied, .restricted:
            error = "Microphone access denied. Enable in System Settings → Privacy & Security → Microphone."
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.requestSpeechAuthAndBegin() }
                    else { self?.error = "Microphone access denied." }
                }
            }
            return
        case .authorized: break
        @unknown default: break
        }
        requestSpeechAuthAndBegin()
    }

    private func requestSpeechAuthAndBegin() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.beginRecognition()
                } else {
                    self?.error = "Speech recognition not authorized. Enable in System Settings → Privacy & Security → Speech Recognition."
                }
            }
        }
    }

    // MARK: - Engine Lifecycle

    private func cleanupRecognition() {
        pendingRestart?.cancel()
        pendingRestart = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        if audioEngine.isRunning { audioEngine.stop() }
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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
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

    // MARK: - Fuzzy Matching (internal for testability)

    func matchCharacters(spoken: String) {
        let charResult = charLevelMatch(spoken: spoken)
        let wordResult = wordLevelMatch(spoken: spoken)
        let best = max(charResult, wordResult)
        let newCount = matchStartOffset + best
        if newCount > recognizedCharCount {
            recognizedCharCount = min(newCount, sourceText.count)
        }
    }

    func charLevelMatch(spoken: String) -> Int {
        let remainingSource = String(sourceText.dropFirst(matchStartOffset))
        let src = Array(remainingSource.lowercased().unicodeScalars).map { Character($0) }
        let spk = Array(Self.normalize(spoken).unicodeScalars).map { Character($0) }

        var si = 0
        var ri = 0
        var lastGoodOrigIndex = 0

        while si < src.count && ri < spk.count {
            let sc = src[si]
            let rc = spk[ri]

            if !sc.isLetter && !sc.isNumber { si += 1; continue }
            if !rc.isLetter && !rc.isNumber { ri += 1; continue }

            if sc == rc {
                si += 1
                ri += 1
                lastGoodOrigIndex = si
            } else {
                var found = false
                let maxSkipR = min(3, spk.count - ri - 1)
                if maxSkipR >= 1 {
                    for skipR in 1...maxSkipR {
                        if ri + skipR < spk.count && spk[ri + skipR] == sc {
                            ri = ri + skipR; found = true; break
                        }
                    }
                }
                if found { continue }
                let maxSkipS = min(3, src.count - si - 1)
                if maxSkipS >= 1 {
                    for skipS in 1...maxSkipS {
                        if si + skipS < src.count && src[si + skipS] == rc {
                            si = si + skipS; found = true; break
                        }
                    }
                }
                if found { continue }
                si += 1; ri += 1; lastGoodOrigIndex = si
            }
        }
        return lastGoodOrigIndex
    }

    func wordLevelMatch(spoken: String) -> Int {
        let remainingSource = String(sourceText.dropFirst(matchStartOffset))
        let sourceWords = remainingSource.split(separator: " ").map { String($0) }
        let spokenWords = spoken.lowercased().split(separator: " ").map { String($0) }

        var si = 0
        var ri = 0
        var matchedCharCount = 0

        while si < sourceWords.count && ri < spokenWords.count {
            if Self.isAnnotationWord(sourceWords[si]) {
                matchedCharCount += sourceWords[si].count
                if si < sourceWords.count - 1 { matchedCharCount += 1 }
                si += 1
                continue
            }

            let srcWord = sourceWords[si].lowercased().filter { $0.isLetter || $0.isNumber }
            let spkWord = spokenWords[ri].filter { $0.isLetter || $0.isNumber }

            if srcWord == spkWord || isFuzzyMatch(srcWord, spkWord) {
                matchedCharCount += sourceWords[si].count
                if si < sourceWords.count - 1 { matchedCharCount += 1 }
                si += 1; ri += 1
            } else {
                var foundSpk = false
                let maxSpkSkip = min(3, spokenWords.count - ri - 1)
                for skip in 1...max(1, maxSpkSkip) where skip <= maxSpkSkip {
                    let nextSpk = spokenWords[ri + skip].filter { $0.isLetter || $0.isNumber }
                    if srcWord == nextSpk || isFuzzyMatch(srcWord, nextSpk) {
                        ri += skip; foundSpk = true; break
                    }
                }
                if foundSpk { continue }

                var foundSrc = false
                let maxSrcSkip = min(3, sourceWords.count - si - 1)
                for skip in 1...max(1, maxSrcSkip) where skip <= maxSrcSkip {
                    let nextSrc = sourceWords[si + skip].lowercased().filter { $0.isLetter || $0.isNumber }
                    if nextSrc == spkWord || isFuzzyMatch(nextSrc, spkWord) {
                        for s in 0..<skip { matchedCharCount += sourceWords[si + s].count + 1 }
                        si += skip; foundSrc = true; break
                    }
                }
                if foundSrc { continue }

                if srcWord.isEmpty {
                    matchedCharCount += sourceWords[si].count
                    if si < sourceWords.count - 1 { matchedCharCount += 1 }
                    si += 1; continue
                }
                ri += 1
            }
        }

        while si < sourceWords.count && Self.isAnnotationWord(sourceWords[si]) {
            matchedCharCount += sourceWords[si].count
            if si < sourceWords.count - 1 { matchedCharCount += 1 }
            si += 1
        }
        return matchedCharCount
    }

    func isFuzzyMatch(_ a: String, _ b: String) -> Bool {
        if a.isEmpty || b.isEmpty { return false }
        if a == b { return true }
        if a.hasPrefix(b) || b.hasPrefix(a) { return true }
        if a.contains(b) || b.contains(a) { return true }
        let shared = zip(a, b).prefix(while: { $0 == $1 }).count
        let shorter = min(a.count, b.count)
        if shorter >= 2 && shared >= max(2, shorter * 3 / 5) { return true }
        let dist = editDistance(a, b)
        if shorter <= 4 { return dist <= 1 }
        if shorter <= 8 { return dist <= 2 }
        return dist <= max(a.count, b.count) / 3
    }

    private func editDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        var dp = Array(0...b.count)
        for i in 1...a.count {
            var prev = dp[0]
            dp[0] = i
            for j in 1...b.count {
                let temp = dp[j]
                dp[j] = a[i-1] == b[j-1] ? prev : min(prev, dp[j], dp[j-1]) + 1
                prev = temp
            }
        }
        return dp[b.count]
    }

    static func normalize(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
    }

    private static func isAnnotationWord(_ word: String) -> Bool {
        if word.hasPrefix("[") && word.hasSuffix("]") { return true }
        return word.filter { $0.isLetter || $0.isNumber }.isEmpty
    }
}
```

- [ ] **Step 2.4: Xcode 프로젝트에 Privacy 설명 추가**

Xcode에서: `CunningPaper` 타겟 선택 → `Info` 탭 → `+` 버튼으로 두 항목 추가:
- Key: `Privacy - Microphone Usage Description`  
  Value: `"CunningPaper needs microphone access for voice tracking mode."`
- Key: `Privacy - Speech Recognition Usage Description`  
  Value: `"CunningPaper uses on-device speech recognition to highlight words as you read."`

- [ ] **Step 2.5: 테스트 실행 — 통과 확인**

`CunningPaperTests/SpeechRecognizerTests.swift` 전체 테스트 통과 확인.

- [ ] **Step 2.6: 커밋**

```bash
git add CunningPaper/Reading/SpeechRecognizer.swift \
        CunningPaperTests/SpeechRecognizerTests.swift
git commit -m "feat: add SpeechRecognizer with fuzzy matching (ported from Textream)"
```

---

## Task 3: MarqueeTextView

Textream `MarqueeTextView.swift`에서 필요한 부분만 이식한다. 제거: `ElapsedTimeView`, `AudioWaveformView`, `AudioWaveformProgressView`, `ScrollWheelView`, `ScrollWheelNSView`, smooth scroll 관련 props (`smoothScroll`, `smoothWordProgress`, `onManualScroll`), `onWordTap`.

**Files:**
- Create: `CunningPaper/Overlay/MarqueeTextView.swift`

---

- [ ] **Step 3.1: MarqueeTextView 생성**

`CunningPaper/Overlay/MarqueeTextView.swift`:

```swift
import SwiftUI

// MARK: - CJK-aware word splitting (needed by both MarqueeTextView and SpeechRecognizer)

extension Unicode.Scalar {
    var isCJK: Bool {
        let v = value
        return (v >= 0x4E00 && v <= 0x9FFF)
            || (v >= 0x3400 && v <= 0x4DBF)
            || (v >= 0x20000 && v <= 0x2A6DF)
            || (v >= 0xF900 && v <= 0xFAFF)
            || (v >= 0x3040 && v <= 0x309F)
            || (v >= 0x30A0 && v <= 0x30FF)
            || (v >= 0xAC00 && v <= 0xD7AF)
    }
}

func splitTextIntoWords(_ text: String) -> [String] {
    let tokens = text.replacingOccurrences(of: "\n", with: " ")
        .split(omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })
        .map { String($0) }

    var result: [String] = []
    for token in tokens {
        guard token.unicodeScalars.contains(where: { $0.isCJK }) else {
            result.append(token)
            continue
        }
        var buffer = ""
        for char in token {
            if char.unicodeScalars.first.map({ $0.isCJK }) == true {
                if !buffer.isEmpty { result.append(buffer); buffer = "" }
                result.append(String(char))
            } else {
                buffer.append(char)
            }
        }
        if !buffer.isEmpty { result.append(buffer) }
    }
    return result
}

// MARK: - Data

struct WordItem: Identifiable {
    let id: Int
    let word: String
    let charOffset: Int
    let isAnnotation: Bool
}

// MARK: - Preference key for word Y positions

struct WordYPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - MarqueeTextView (public entry point)

struct MarqueeTextView: View {
    let text: String
    let highlightedCharCount: Int
    var fontSize: Double = 18

    private var words: [String] { splitTextIntoWords(text) }

    var body: some View {
        SpeechScrollView(
            words: words,
            highlightedCharCount: highlightedCharCount,
            font: .systemFont(ofSize: fontSize, weight: .semibold)
        )
    }
}

// MARK: - SpeechScrollView

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
        GeometryReader { geo in
            WordFlowLayout(
                words: words,
                highlightedCharCount: highlightedCharCount,
                font: font,
                highlightColor: highlightColor,
                cueColor: cueColor,
                cueUnreadOpacity: cueUnreadOpacity,
                cueReadOpacity: cueReadOpacity,
                containerWidth: geo.size.width,
                scrollOffset: scrollOffset,
                viewportHeight: geo.size.height
            )
            .onPreferenceChange(WordYPreferenceKey.self) { positions in
                let wasEmpty = wordYPositions.isEmpty
                wordYPositions = positions
                if wasEmpty && !positions.isEmpty {
                    recalcCenter(containerHeight: containerHeight)
                }
            }
            .offset(y: scrollOffset)
            .animation(.easeOut(duration: 0.5), value: scrollOffset)
            .onChange(of: geo.size.height) { _, newHeight in
                containerHeight = newHeight
                if highlightedCharCount == 0 {
                    let lineHeight = font.pointSize * 1.4
                    scrollOffset = newHeight * 0.5 - lineHeight * 0.5
                } else {
                    recalcCenter(containerHeight: newHeight)
                }
            }
            .onChange(of: highlightedCharCount) { _, _ in
                recalcCenter(containerHeight: containerHeight)
            }
            .onChange(of: words) { _, _ in
                let lineHeight = font.pointSize * 1.4
                scrollOffset = containerHeight * 0.5 - lineHeight * 0.5
                wordYPositions = [:]
            }
            .onAppear {
                containerHeight = geo.size.height
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
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func recalcCenter(containerHeight: CGFloat) {
        let center = containerHeight * 0.5
        let wordIdx = activeWordIndex()
        if let wordY = wordYPositions[wordIdx] {
            let target = center - wordY
            if abs(scrollOffset - target) > 1 {
                scrollOffset = target
            }
        }
    }

    private func activeWordIndex() -> Int {
        var offset = 0
        for (i, word) in words.enumerated() {
            let end = offset + word.count
            if highlightedCharCount <= end { return i }
            offset = end + 1
        }
        return max(0, words.count - 1)
    }
}

// MARK: - WordFlowLayout

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
        let ratio = intrinsicHeight / font.pointSize
        return ratio > 1.5 ? 2 : 8
    }

    private static var _cacheKey: String = ""
    private static var _cachedItems: [WordItem] = []
    private static var _cachedLines: [[WordItem]] = []

    private func cachedLayout() -> ([WordItem], [[WordItem]]) {
        let key = "\(words.count)|\(words.first ?? "")|\(words.last ?? "")|\(font.pointSize)|\(Int(containerWidth))"
        if key == Self._cacheKey {
            return (Self._cachedItems, Self._cachedLines)
        }
        let items = buildItems()
        let lines = buildLines(items: items)
        Self._cacheKey = key
        Self._cachedItems = items
        Self._cachedLines = lines
        return (items, lines)
    }

    private func nextWordIndex(items: [WordItem]) -> Int {
        for item in items {
            if item.isAnnotation { continue }
            let charsIntoWord = highlightedCharCount - item.charOffset
            let litCount = max(0, min(item.word.count, charsIntoWord))
            let letterCount = max(1, item.word.filter { $0.isLetter || $0.isNumber }.count)
            if litCount < letterCount { return item.id }
        }
        return -1
    }

    var body: some View {
        let (items, lines) = cachedLayout()
        let nextIdx = nextWordIndex(items: items)
        let totalLines = lines.count
        let lineH = ceil(font.ascender - font.descender + font.leading) + lineSpacing

        let canCull = viewportHeight > 0 && totalLines > 0
        let buffer: CGFloat = 400
        let startLine = canCull ? max(0, min(totalLines, Int(floor((-scrollOffset - buffer) / lineH)))) : 0
        let endLine = canCull ? max(startLine, min(totalLines, Int(ceil((viewportHeight - scrollOffset + buffer) / lineH)))) : totalLines

        VStack(alignment: .leading, spacing: lineSpacing) {
            if startLine > 0 {
                Color.clear.frame(height: CGFloat(startLine) * lineH)
            }
            ForEach(startLine..<endLine, id: \.self) { lineIdx in
                HStack(spacing: 0) {
                    ForEach(lines[lineIdx], id: \.id) { item in
                        wordView(for: item, isNextWord: item.id == nextIdx)
                    }
                }
            }
            if endLine < totalLines {
                Color.clear.frame(height: CGFloat(totalLines - endLine) * lineH)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coordinateSpace(name: "flowLayout")
    }

    private func wordView(for item: WordItem, isNextWord: Bool) -> some View {
        let wordLen = item.word.count
        let charsIntoWord = highlightedCharCount - item.charOffset
        let litCount = max(0, min(wordLen, charsIntoWord))
        let letterCount = max(1, item.word.filter { $0.isLetter || $0.isNumber }.count)
        let isFullyLit = litCount >= letterCount
        let isCurrentWord = isNextWord || (charsIntoWord >= 0 && !isFullyLit)

        if item.isAnnotation {
            let annotationColor: Color = isFullyLit
                ? cueColor.opacity(cueReadOpacity)
                : cueColor.opacity(cueUnreadOpacity)
            return Text(item.word + " ")
                .font(Font(font).italic())
                .foregroundStyle(annotationColor)
                .background(yReporter(for: item.id))
        }

        let dimColor: Color = isCurrentWord ? highlightColor.opacity(0.6) : highlightColor
        let wordColor: Color = isFullyLit ? highlightColor.opacity(0.3) : dimColor

        return Text(item.word + " ")
            .font(Font(font))
            .foregroundStyle(wordColor)
            .underline(isCurrentWord, color: wordColor)
            .background(yReporter(for: item.id))
    }

    private func yReporter(for id: Int) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: WordYPreferenceKey.self,
                value: [id: geo.frame(in: .named("flowLayout")).midY]
            )
        }
    }

    private func buildItems() -> [WordItem] {
        var items: [WordItem] = []
        var offset = 0
        for (i, word) in words.enumerated() {
            let isAnnotation = isAnnotationWord(word)
            items.append(WordItem(id: i, word: word, charOffset: offset, isAnnotation: isAnnotation))
            offset += word.count + 1
        }
        return items
    }

    private func isAnnotationWord(_ word: String) -> Bool {
        if word.hasPrefix("[") && word.hasSuffix("]") { return true }
        return word.filter { $0.isLetter || $0.isNumber }.isEmpty
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
```

- [ ] **Step 3.2: 빌드 확인**

Xcode에서 `CunningPaper` 타겟 빌드. 컴파일 오류 없음 확인.

- [ ] **Step 3.3: 커밋**

```bash
git add CunningPaper/Overlay/MarqueeTextView.swift
git commit -m "feat: add MarqueeTextView with word-tracking scroll (ported from Textream)"
```

---

## Task 4: ReadingEngine

**Files:**
- Create: `CunningPaper/Reading/ReadingEngine.swift`
- Modify: `CunningPaperTests/ReadingEngineTests.swift`

---

- [ ] **Step 4.1: ReadingEngine 테스트 추가**

`CunningPaperTests/ReadingEngineTests.swift`에 추가 (기존 테스트 유지, 아래 테스트 append):

```swift
    // MARK: - ReadingEngine state

    func testEngineInitialState() {
        let engine = ReadingEngine()
        XCTAssertFalse(engine.isActive)
        XCTAssertEqual(engine.highlightedCharCount, 0)
        XCTAssertEqual(engine.fullText, "")
    }

    func testEngineStopResetsState() {
        let engine = ReadingEngine()
        // Simulate active state
        engine.simulateActive(text: "hello world", charCount: 5)
        engine.stop()
        XCTAssertFalse(engine.isActive)
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }

    func testManualAdvanceParagraph() {
        let engine = ReadingEngine()
        // Two paragraphs: "Hello world" and "Goodbye world"
        // collapsed: "Hello world Goodbye world"
        // paragraph offsets: [0, 12]
        engine.simulateManual(paragraphOffsets: [0, 12], total: "Hello world Goodbye world")
        engine.advanceParagraph()
        XCTAssertEqual(engine.highlightedCharCount, 12)
    }

    func testManualRetractParagraph() {
        let engine = ReadingEngine()
        engine.simulateManual(paragraphOffsets: [0, 12], total: "Hello world Goodbye world")
        engine.advanceParagraph() // go to paragraph 1 (charCount = 12)
        engine.retractParagraph() // back to paragraph 0 (charCount = 0)
        XCTAssertEqual(engine.highlightedCharCount, 0)
    }

    func testAutoScrollIncreasesCharCount() {
        let engine = ReadingEngine()
        engine.simulateAutoScroll(text: "hello world this is a test")

        let expectation = XCTestExpectation(description: "charCount increases")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertGreaterThan(engine.highlightedCharCount, 0)
            engine.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
```

- [ ] **Step 4.2: 테스트 실행 — 실패 확인**

`ReadingEngine`, `simulateActive`, `simulateManual`, `simulateAutoScroll` 미정의로 컴파일 오류 확인.

- [ ] **Step 4.3: ReadingEngine 생성**

`CunningPaper/Reading/ReadingEngine.swift`:

```swift
import Foundation
import Observation

@Observable
final class ReadingEngine {

    // MARK: - Public state (observed by OverlayView / MarqueeTextView)

    private(set) var highlightedCharCount: Int = 0
    private(set) var isActive: Bool = false
    private(set) var fullText: String = ""

    // MARK: - Private

    private var currentParagraphIndex: Int = 0
    private var paragraphOffsets: [Int] = []
    private var scrollTimer: Timer?
    private var speechRecognizer: SpeechRecognizer?
    private var fractionalChars: Double = 0

    // MARK: - Public API

    /// 카드와 모드 설정으로 읽기 시작. speed는 autoScroll 전용 (글자/초).
    func start(card: CardModel, mode: ReadingMode, speed: Double = 3.0, language: String = "ko-KR") {
        stop()
        let (text, offsets) = buildTextAndOffsets(from: card)
        fullText = text
        paragraphOffsets = offsets
        currentParagraphIndex = 0
        highlightedCharCount = 0
        isActive = true

        switch mode {
        case .manual:
            break // charCount driven by advanceParagraph() / retractParagraph()
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
        fractionalChars = 0
        speechRecognizer?.stop()
        speechRecognizer = nil
    }

    /// Manual 모드 전용: 다음 문단 첫 단어로 charCount 점프
    func advanceParagraph() {
        guard isActive, !paragraphOffsets.isEmpty else { return }
        let nextIndex = min(currentParagraphIndex + 1, paragraphOffsets.count - 1)
        currentParagraphIndex = nextIndex
        highlightedCharCount = paragraphOffsets[nextIndex]
    }

    /// Manual 모드 전용: 이전 문단 첫 단어로 charCount 점프
    func retractParagraph() {
        guard isActive, !paragraphOffsets.isEmpty else { return }
        let prevIndex = max(currentParagraphIndex - 1, 0)
        currentParagraphIndex = prevIndex
        highlightedCharCount = paragraphOffsets[prevIndex]
    }

    // MARK: - Mode drivers

    private func startAutoScroll(speed: Double) {
        let interval = 1.0 / 30.0
        fractionalChars = 0
        scrollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, self.isActive else { return }
            self.fractionalChars += speed * interval
            if self.fractionalChars >= 1 {
                let advance = Int(self.fractionalChars)
                self.fractionalChars -= Double(advance)
                let next = self.highlightedCharCount + advance
                self.highlightedCharCount = min(next, self.fullText.count)
                if self.highlightedCharCount >= self.fullText.count {
                    self.stop()
                }
            }
        }
    }

    private func startVoiceTracking(language: String) {
        let sr = SpeechRecognizer()
        speechRecognizer = sr
        sr.start(with: fullText, language: language)

        // Poll recognizedCharCount at 10 Hz
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, weak sr] timer in
            guard let self, let sr, self.isActive else { timer.invalidate(); return }
            if sr.recognizedCharCount > self.highlightedCharCount {
                self.highlightedCharCount = sr.recognizedCharCount
            }
            if self.highlightedCharCount >= self.fullText.count {
                self.stop()
                timer.invalidate()
            }
        }
    }

    // MARK: - Text processing

    /// CardModel.body → 문단들을 단어 단위로 collapse한 전체 텍스트 + 각 문단의 시작 char offset
    private func buildTextAndOffsets(from card: CardModel) -> (String, [Int]) {
        let paragraphs = card.paragraphs // CardModel의 computed var: 빈 줄 제거된 문단 배열
        var offsets: [Int] = []
        var parts: [String] = []
        var offset = 0

        for paragraph in paragraphs {
            offsets.append(offset)
            let words = splitTextIntoWords(paragraph)
            let collapsed = words.joined(separator: " ")
            parts.append(collapsed)
            offset += collapsed.count + 1 // +1 for space between paragraphs
        }

        return (parts.joined(separator: " "), offsets)
    }

    // MARK: - Test helpers (internal)

    func simulateActive(text: String, charCount: Int) {
        fullText = text
        highlightedCharCount = charCount
        isActive = true
    }

    func simulateManual(paragraphOffsets: [Int], total: String) {
        self.paragraphOffsets = paragraphOffsets
        self.fullText = total
        self.currentParagraphIndex = 0
        self.highlightedCharCount = 0
        self.isActive = true
    }

    func simulateAutoScroll(text: String) {
        fullText = text
        paragraphOffsets = [0]
        highlightedCharCount = 0
        isActive = true
        startAutoScroll(speed: 10.0) // fast for testing
    }
}
```

- [ ] **Step 4.4: 테스트 실행 — 통과 확인**

`CunningPaperTests/ReadingEngineTests.swift` 전체 통과 확인.

- [ ] **Step 4.5: 커밋**

```bash
git add CunningPaper/Reading/ReadingEngine.swift \
        CunningPaperTests/ReadingEngineTests.swift
git commit -m "feat: add ReadingEngine with Manual/AutoScroll/VoiceTracking modes"
```

---

## Task 5: OverlayView — ReadingEngine + MarqueeTextView 연결

**Files:**
- Modify: `CunningPaper/Overlay/OverlayView.swift`

---

- [ ] **Step 5.1: OverlayView 전체 교체**

`CunningPaper/Overlay/OverlayView.swift`를 아래로 교체한다:

```swift
import AppKit
import SwiftData
import SwiftUI

enum ActivePanel: Equatable {
    case none
    case jump
}

struct OverlayView: View {
    @Query(sort: \CardModel.order) private var cards: [CardModel]
    @Query private var prefsArray: [PrefsModel]
    @State private var currentIndex = 0
    @State private var activePanel: ActivePanel = .none
    @State private var engine = ReadingEngine()

    private var prefs: PrefsModel? { prefsArray.first }

    private var currentCard: CardModel? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(prefs?.opacity ?? 0.85))

            MarqueeTextView(
                text: engine.fullText.isEmpty ? (currentCard?.body ?? "No cards yet") : engine.fullText,
                highlightedCharCount: engine.highlightedCharCount,
                fontSize: prefs?.fontSize ?? 24
            )
            .padding(6)

            if activePanel == .jump {
                JumpPanelView(
                    totalCards: cards.count,
                    onJump: { index in
                        currentIndex = index
                        restartEngine()
                        closePanel()
                    },
                    onClose: closePanel
                )
            }
        }
        .padding(6)
        .onAppear {
            restartEngine()
        }
        .onDisappear {
            engine.stop()
        }
        .onChange(of: activePanel) { _, panel in
            updateClickThrough(for: panel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .hotkeyFired)) { note in
            guard
                let rawValue = note.userInfo?["action"] as? String,
                let action = HotkeyAction(rawValue: rawValue)
            else { return }
            handleHotkey(action)
        }
    }

    private func handleHotkey(_ action: HotkeyAction) {
        switch action {
        case .next:
            guard currentIndex < cards.count - 1 else { return }
            currentIndex += 1
            restartEngine()
        case .prev:
            guard currentIndex > 0 else { return }
            currentIndex -= 1
            restartEngine()
        case .jump:
            activePanel = .jump
        case .nextLine:
            if prefs?.readingMode == .manual { engine.advanceParagraph() }
        case .prevLine:
            if prefs?.readingMode == .manual { engine.retractParagraph() }
        case .stop:
            engine.stop()
        case .toggle:
            break
        }
    }

    private func restartEngine() {
        guard let card = currentCard, let prefs else { return }
        engine.start(
            card: card,
            mode: prefs.readingMode,
            speed: prefs.autoScrollSpeed,
            language: prefs.speechLanguage
        )
    }

    private func closePanel() {
        activePanel = .none
    }

    private func updateClickThrough(for panel: ActivePanel) {
        guard let overlayWindow = NSApp.windows.first(where: { $0 is OverlayPanel }) else { return }
        overlayWindow.ignoresMouseEvents = (panel == .none)
    }
}
```

- [ ] **Step 5.2: 빌드 확인**

`CunningPaper` 타겟 빌드. 컴파일 오류 없음 확인.

- [ ] **Step 5.3: 수동 동작 확인**

앱 실행 → 오버레이 표시 → 카드 텍스트가 MarqueeTextView로 표시되는지 확인. Manual 모드에서 단축키로 문단 이동 시 텍스트가 중앙 정렬로 점프하는지 확인.

- [ ] **Step 5.4: 커밋**

```bash
git add CunningPaper/Overlay/OverlayView.swift
git commit -m "feat: wire ReadingEngine and MarqueeTextView into OverlayView"
```

---

## Task 6: PreferencesView — 읽기 설정 섹션 추가

**Files:**
- Modify: `CunningPaper/Editor/Preferences/PreferencesView.swift`

---

- [ ] **Step 6.1: PreferencesView에 읽기 설정 섹션 추가**

`CunningPaper/Editor/Preferences/PreferencesView.swift`의 `body` 안, `Shortcuts` 섹션 바로 위에 아래 블록을 삽입한다:

```swift
preferenceSection(
    title: "Reading",
    description: "Choose how the overlay guides you through your script."
) {
    VStack(alignment: .leading, spacing: 0) {
        // Mode picker
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Reading Mode")
                    .font(.system(size: 13, weight: .medium))
                Text("Voice Tracking highlights words as you speak. Auto-scroll advances at a set speed. Manual uses hotkeys.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Picker("", selection: Binding(
                get: { prefs.readingMode },
                set: { prefs.readingMode = $0; savePreferences() }
            )) {
                Text("Voice Tracking").tag(ReadingMode.voiceTracking)
                Text("Auto-scroll").tag(ReadingMode.autoScroll)
                Text("Manual").tag(ReadingMode.manual)
            }
            .pickerStyle(.segmented)
            .frame(width: 280)
            .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(rowBackground(showDivider: true))

        // Auto-scroll speed slider (autoScroll 모드에서만 활성화)
        sliderRow(
            title: "Scroll Speed",
            detail: "Characters per second. Only applies in Auto-scroll mode.",
            valueText: String(format: "%.1f chars/s", prefs.autoScrollSpeed),
            value: Binding(
                get: { prefs.autoScrollSpeed },
                set: { prefs.autoScrollSpeed = $0; savePreferences() }
            ),
            range: 0.5...10.0,
            step: 0.5,
            showDivider: true
        )
        .disabled(prefs.readingMode != .autoScroll)
        .opacity(prefs.readingMode == .autoScroll ? 1.0 : 0.4)

        // Speech language picker (voiceTracking 모드에서만 활성화)
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Recognition Language")
                    .font(.system(size: 13, weight: .medium))
                Text("Language used for on-device speech recognition.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Picker("", selection: Binding(
                get: { prefs.speechLanguage },
                set: { prefs.speechLanguage = $0; savePreferences() }
            )) {
                Text("한국어").tag("ko-KR")
                Text("English (US)").tag("en-US")
                Text("日本語").tag("ja-JP")
                Text("中文 (简体)").tag("zh-CN")
            }
            .frame(width: 200)
            .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(rowBackground(showDivider: false))
        .disabled(prefs.readingMode != .voiceTracking)
        .opacity(prefs.readingMode == .voiceTracking ? 1.0 : 0.4)
    }
}
```

- [ ] **Step 6.2: Shortcuts 섹션에 Stop Reading 단축키 추가**

`PreferencesView.swift`의 Shortcuts 섹션에서 마지막 `shortcutRow("Toggle Overlay", ...)` 바로 위에 삽입:

```swift
shortcutRow("Stop Reading", name: .stop, showDivider: true)
```

기존의 `shortcutRow("Toggle Overlay", name: .toggle, showDivider: false)` 는 유지.

- [ ] **Step 6.3: 빌드 확인**

`CunningPaper` 타겟 빌드. 컴파일 오류 없음 확인.

- [ ] **Step 6.4: 수동 동작 확인**

앱 실행 → 에디터 → Preferences:
1. Reading 섹션이 Shortcuts 섹션 위에 표시되는지 확인
2. 모드 Picker에서 `Auto-scroll` 선택 시 Scroll Speed 슬라이더가 활성화되는지 확인
3. `Voice Tracking` 선택 시 Recognition Language picker가 활성화되는지 확인
4. `Manual` 선택 시 슬라이더와 언어 picker 모두 흐려지는지 확인
5. Stop Reading 단축키가 Shortcuts 섹션에 표시되는지 확인

- [ ] **Step 6.5: 커밋**

```bash
git add CunningPaper/Editor/Preferences/PreferencesView.swift
git commit -m "feat: add reading mode, speed, language, and stop shortcut to PreferencesView"
```

---

## Self-Review

**Spec coverage 체크:**
- ✅ ReadingMode 3가지 — Task 1
- ✅ PrefsModel readingMode, autoScrollSpeed, speechLanguage — Task 1
- ✅ HotkeyManager stop action (사용자 설정 가능) — Task 1 + Task 6
- ✅ SpeechRecognizer 퍼지 매칭 이식 — Task 2
- ✅ MarqueeTextView 이식 (마우스 스크롤·탭 점프 제거) — Task 3
- ✅ ReadingEngine start/stop/advanceParagraph/retractParagraph — Task 4
- ✅ OverlayView: CardDisplayView → MarqueeTextView 교체 — Task 5
- ✅ OverlayView: 카드 전환 시 engine 재시작 — Task 5
- ✅ OverlayView: onAppear/onDisappear lifecycle — Task 5
- ✅ PreferencesView 읽기 설정 섹션 — Task 6
- ✅ Privacy usage descriptions — Task 2 (Step 2.4)

**Type consistency 체크:**
- `ReadingEngine.start(card:mode:speed:language:)` → OverlayView에서 `prefs.autoScrollSpeed`, `prefs.speechLanguage` 로 호출 ✅
- `MarqueeTextView(text:highlightedCharCount:fontSize:)` → OverlayView에서 `engine.highlightedCharCount`, `prefs.fontSize` 로 호출 ✅
- `SpeechRecognizer.start(with:language:)` → ReadingEngine에서 호출 ✅
- `HotkeyAction.stop` → OverlayView.handleHotkey에서 `engine.stop()` 호출 ✅
- `engine.advanceParagraph()` / `engine.retractParagraph()` → OverlayView .nextLine/.prevLine에서 호출 ✅

**Placeholder 없음** — 모든 step에 실제 코드 포함 확인.
