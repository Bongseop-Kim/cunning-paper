# Textream Reading Engine — Design Spec

**Date:** 2026-04-06
**Branch:** feat/textream
**Status:** Approved

---

## Overview

Textream의 핵심 기능(Word Tracking, Classic Auto-scroll, MarqueeTextView)을 cunning-paper의 기존 카드 기반 아키텍처에 통합한다. 에디터와 오버레이의 분리는 유지하며, 오버레이는 단축키로만 조작된다.

---

## Decisions

| 항목 | 결정 |
|------|------|
| 통합 단위 | 카드 1개 = 스크립트 1개 |
| 모드 선택 | 에디터 Preferences에서 기본값 지정 |
| 오버레이 텍스트 표시 | Marquee Flow (단어 하이라이트 + 중앙 정렬) |
| 오버레이 컨트롤 | 단축키만 (정지 단축키는 사용자 설정 가능, 기본값 Esc) |
| 마이크 음소거 | 제거 — 정지(stop)로 통합 |
| 속도 조절 | 오버레이에서 제거. Auto-scroll 모드 전용으로 에디터 Preferences에서만 설정 |
| 읽기 모드 수 | 3가지 (Manual / Auto-scroll / Voice Tracking) |

---

## Reading Modes

| 모드 | 동작 | 마이크 |
|------|------|--------|
| **Manual** | 기존 단축키로 문단 이동 | 불필요 |
| **Auto-scroll** | 에디터에서 설정한 속도로 charCount 자동 증가 | 불필요 |
| **Voice Tracking** | SFSpeechRecognizer로 발화 인식, 매칭된 단어까지 하이라이트 + 중앙 정렬 | 필수 |

---

## Architecture

### 전체 데이터 흐름

```
CardModel ──text──▶ ReadingEngine ──highlightedCharCount──▶ MarqueeTextView
                         ▲
HotkeyManager ──stop/advanceParagraph──▶ ReadingEngine
                         ▲
SpeechRecognizer ──recognizedCharCount──▶ ReadingEngine
                         ▲
PrefsModel ──readingMode / autoScrollSpeed / speechLanguage──▶ ReadingEngine
```

### 핵심 설계 원칙

세 모드 모두 `ReadingEngine`의 `highlightedCharCount` 단일 값만 업데이트한다. `MarqueeTextView`는 이 값만 보고 렌더링하므로 모드가 바뀌어도 뷰는 변경 없다.

---

## New Files

### `ReadingEngine.swift`

```swift
@Observable final class ReadingEngine {
    var highlightedCharCount: Int = 0   // MarqueeTextView가 관찰
    var isActive: Bool = false
    private(set) var fullText: String = ""

    private var scrollTimer: Timer?          // auto-scroll용
    private var speechRecognizer: SpeechRecognizer?  // voice tracking용

    func start(card: CardModel, mode: ReadingMode, prefs: PrefsModel)
    func stop()                          // HotkeyManager가 호출
    func advanceParagraph()              // Manual 모드 단축키
}
```

**모드별 charCount 드라이버:**
- **Manual**: `advanceParagraph()` 호출 시 다음 문단의 시작 offset으로 charCount 점프 (MarqueeTextView가 해당 문단 첫 단어를 중앙에 표시)
- **Auto-scroll**: `Timer`가 `autoScrollSpeed`(글자/초)로 charCount 증가
- **Voice Tracking**: `SpeechRecognizer.recognizedCharCount`를 charCount에 반영

### `SpeechRecognizer.swift` (Textream 이식)

Textream의 `SpeechRecognizer.swift`에서 선택적 이식:

| 항목 | 포함 여부 | 이유 |
|------|-----------|------|
| 이중 퍼지 매칭 (charLevel + wordLevel) | ✓ | 핵심 알고리즘 |
| recognizedCharCount | ✓ | ReadingEngine에 전달 |
| 음성 감지 VAD (isListening) | ✓ | 상태 표시용 |
| 오디오 레벨 RMS / 웨이브폼 | ✗ | cunning-paper에 불필요 |
| jumpTo(), updateText() | ✗ | 탭 점프·라이브 편집 없음 |
| 다국어 언어 설정 | ✓ | PrefsModel.speechLanguage 연결 |

### `MarqueeTextView.swift` (Textream 이식)

Textream의 `MarqueeTextView.swift`에서 선택적 이식:

| 항목 | 포함 여부 | 이유 |
|------|-----------|------|
| WordItem, WordFlowLayout | ✓ | 단어 토큰화 + 플로우 레이아웃 |
| recalcCenter() | ✓ | 현재 단어 중앙 정렬 |
| 하이라이트 (highlightedCharCount 기반) | ✓ | ReadingEngine에서 주입 |
| 뷰포트 컬링 (400px 버퍼) | ✓ | 성능 최적화 |
| 마우스 스크롤 damped physics | ✗ | 단축키 전용 서비스 |
| CJK 인식 토큰화 | ✗ | 초기 범위 제외, 필요 시 추가 |
| 폰트/컬러 | ✓ | cunning-paper PrefsModel과 연결 |

**인터페이스:**
```swift
MarqueeTextView(
    text: engine.fullText,
    highlightedCharCount: engine.highlightedCharCount
)
```

**모드별 시각 동작:**

| 모드 | 현재 단어 위치 | 하이라이트 |
|------|----------------|------------|
| Manual | 현재 문단 첫 단어를 중앙으로 | 현재 문단 전체 밝게 |
| Auto-scroll | 현재 단어를 중앙으로 | 읽은 단어 밝게, 나머지 흐리게 |
| Voice Tracking | 인식된 단어를 중앙으로 | 인식된 단어까지 밝게, 나머지 흐리게 |

---

## Modified Files

### `PrefsModel.swift`

추가 필드:
```swift
var readingMode: ReadingMode = .voiceTracking
var autoScrollSpeed: Double = 2.0    // 글자/초, auto-scroll 전용
var speechLanguage: String = "ko-KR" // voice tracking 전용
```

### `ReadingMode.swift` (enum, 신규 또는 PrefsModel 내 정의)

```swift
enum ReadingMode: String, CaseIterable {
    case manual
    case autoScroll
    case voiceTracking
}
```

### `OverlayView.swift`

- `CardDisplayView` → `MarqueeTextView`로 교체 (오버레이에서만)
- `ReadingEngine` 인스턴스 주입/관찰
- `CardDisplayView`는 에디터 미리보기에서 유지

### `PreferencesView.swift`

읽기 설정 섹션 추가:
- **읽기 모드** Picker (음성 추적 / 자동 스크롤 / 수동)
- **스크롤 속도** Slider — Auto-scroll 모드에서만 활성화
- **인식 언어** Picker — Voice Tracking 모드에서만 활성화

### `HotkeyManager.swift`

- "읽기 정지" 단축키 항목 추가 → `engine.stop()` 호출
- 기본값 Esc, 사용자 설정 가능 (기존 단축키 설정 방식과 동일)
- Manual 모드의 문단 이동 단축키 → `engine.advanceParagraph()` 위임

---

## Out of Scope

- 마우스 스크롤로 위치 이동
- 단어 탭으로 위치 점프
- 웨이브폼 시각화
- Director Mode / Remote Connection
- CJK 특수 토큰화
- Multi-page 연속 읽기
- 오버레이 내 실시간 컨트롤 UI
