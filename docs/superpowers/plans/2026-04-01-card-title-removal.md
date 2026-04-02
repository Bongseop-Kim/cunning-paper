# Card Title Removal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove persistent card titles, derive list-only summary text from card bodies, and delete overlay search so cards are body-first across the app.

**Architecture:** Update `CardModel` and migration parsing first so persistence matches the new schema and summary helpers live in one place. Then simplify editor and overlay surfaces to consume paragraph/body-derived data only, followed by removing search-specific hotkey, settings, and project references so the app has no dead title/search paths.

**Tech Stack:** Swift, SwiftUI, SwiftData, XCTest, Xcode project file management

---

## File Structure

- Modify: `CunningPaper/Data/CardModel.swift`
  - Remove `title` storage and add body-derived helpers for list summary text.
- Modify: `CunningPaper/Data/MigrationService.swift`
  - Continue parsing legacy JSON with `title`, but discard it when creating new `CardModel` instances.
- Modify: `CunningPaper/Editor/Cards/CardListView.swift`
  - Replace title row with derived first-word summary.
- Modify: `CunningPaper/Editor/Cards/CardDetailView.swift`
  - Remove title field and title binding path.
- Modify: `CunningPaper/Editor/Cards/CardStudioView.swift`
  - Stop passing title into preview.
- Modify: `CunningPaper/Editor/Cards/CardPreviewPane.swift`
  - Remove title input and title-specific display options.
- Modify: `CunningPaper/Editor/Cards/CardEmptyStateView.swift`
  - Create cards using body-only model shape; keep sample content body-first.
- Modify: `CunningPaper/Overlay/CardDisplayView.swift`
  - Remove title properties and title rendering block.
- Modify: `CunningPaper/Overlay/OverlayView.swift`
  - Remove search panel state and search action handling.
- Delete: `CunningPaper/Overlay/SearchPanelView.swift`
  - Remove overlay search UI entirely.
- Modify: `CunningPaper/System/HotkeyManager.swift`
  - Remove search action and shortcut registration.
- Modify: `CunningPaper/Editor/Preferences/PreferencesView.swift`
  - Remove search shortcut row.
- Modify: `CunningPaper.xcodeproj/project.pbxproj`
  - Remove `SearchPanelView.swift` file reference and build phase entry.
- Modify: `CunningPaperTests/ModelTests.swift`
  - Replace title-based model tests with body-summary helper coverage.
- Modify: `CunningPaperTests/MigrationServiceTests.swift`
  - Update migration expectations for body-only cards.

### Task 1: Update the Card Model and Migration Path

**Files:**
- Modify: `CunningPaper/Data/CardModel.swift`
- Modify: `CunningPaper/Data/MigrationService.swift`
- Modify: `CunningPaperTests/ModelTests.swift`
- Modify: `CunningPaperTests/MigrationServiceTests.swift`

- [ ] **Step 1: Write the failing model and migration tests**

Add and update tests in `CunningPaperTests/ModelTests.swift` and `CunningPaperTests/MigrationServiceTests.swift` to assert the new body-only behavior:

```swift
func testCardModelListHeadlineUsesFirstWord() {
    let card = CardModel(body: "Focus drives clarity\nSecond line")
    XCTAssertEqual(card.listHeadline, "Focus")
}

func testCardModelListHeadlineFallsBackForEmptyBody() {
    let card = CardModel(body: "   \n\t")
    XCTAssertEqual(card.listHeadline, "Empty")
    XCTAssertEqual(card.listSubheadline, "Empty card")
}

func testCardModelListSubheadlineUsesFirstLine() {
    let card = CardModel(body: "Focus drives clarity\nSecond line")
    XCTAssertEqual(card.listSubheadline, "Focus drives clarity")
}

func testParseCardsJSONReturnsBodyOnlyCards() throws {
    let json = """
    [{"id":"550e8400-e29b-41d4-a716-446655440000","title":"Intro","body":"Hello","order":0,"createdAt":"2024-01-01T00:00:00Z","updatedAt":"2024-01-01T00:00:00Z"}]
    """

    let cards = try MigrationService.parseCardsJSON(Data(json.utf8))
    XCTAssertEqual(cards.count, 1)
    XCTAssertEqual(cards[0].body, "Hello")
    XCTAssertEqual(cards[0].listHeadline, "Hello")
}
```

- [ ] **Step 2: Run the focused tests to verify they fail**

Run:

```bash
xcodebuild test -project "$PWD/CunningPaper.xcodeproj" -scheme CunningPaper -destination 'platform=macOS' -derivedDataPath "${DERIVED_DATA_DIR:-/tmp/CunningPaperDerivedData}" -only-testing:CunningPaperTests/ModelTests -only-testing:CunningPaperTests/MigrationServiceTests
```

Expected: FAIL because `CardModel` still requires `title`, the new helper properties do not exist, and the migration test still expects `title`.

- [ ] **Step 3: Implement the minimal model and migration changes**

Update `CunningPaper/Data/CardModel.swift` so the type becomes body-first:

```swift
@Model
final class CardModel {
    var id: UUID
    var body: String
    var order: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        body: String,
        order: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.body = body
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var listHeadline: String {
        paragraphs.first?
            .split(whereSeparator: \.isWhitespace)
            .first
            .map(String.init) ?? "Empty"
    }

    var listSubheadline: String {
        paragraphs.first ?? "Empty card"
    }
}
```

Update `CunningPaper/Data/MigrationService.swift` to keep decoding legacy JSON with `title`, but stop storing it:

```swift
return legacyCards.map { legacyCard in
    CardModel(
        id: UUID(uuidString: legacyCard.id) ?? UUID(),
        body: legacyCard.body,
        order: legacyCard.order,
        createdAt: formatter.date(from: legacyCard.createdAt) ?? Date(),
        updatedAt: formatter.date(from: legacyCard.updatedAt) ?? Date()
    )
}
```

- [ ] **Step 4: Run the focused tests to verify they pass**

Run:

```bash
xcodebuild test -project "$PWD/CunningPaper.xcodeproj" -scheme CunningPaper -destination 'platform=macOS' -derivedDataPath "${DERIVED_DATA_DIR:-/tmp/CunningPaperDerivedData}" -only-testing:CunningPaperTests/ModelTests -only-testing:CunningPaperTests/MigrationServiceTests
```

Expected: PASS for `ModelTests` and `MigrationServiceTests`.

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Data/CardModel.swift CunningPaper/Data/MigrationService.swift CunningPaperTests/ModelTests.swift CunningPaperTests/MigrationServiceTests.swift
git commit -m "refactor: remove stored card titles"
```

### Task 2: Remove Title Editing and Title Rendering From Editor Surfaces

**Files:**
- Modify: `CunningPaper/Editor/Cards/CardListView.swift`
- Modify: `CunningPaper/Editor/Cards/CardDetailView.swift`
- Modify: `CunningPaper/Editor/Cards/CardStudioView.swift`
- Modify: `CunningPaper/Editor/Cards/CardPreviewPane.swift`
- Modify: `CunningPaper/Editor/Cards/CardEmptyStateView.swift`
- Test: manual editor verification

- [ ] **Step 1: Add the body-only list and editor assertions you will verify manually**

Write down the exact manual checks in the working notes or commit message draft before editing code so the UI work has a fixed acceptance target:

```text
1. New card creation works without a title field.
2. List rows show first-word headline, first-line summary, and paragraph count.
3. Empty cards show "Empty" and "Empty card".
4. Preview pane shows only paragraphs and no title row.
```

- [ ] **Step 2: Run the app once to capture the current baseline**

Run:

```bash
xcodebuild -project "$PWD/CunningPaper.xcodeproj" -scheme CunningPaper -destination 'platform=macOS' -derivedDataPath "${DERIVED_DATA_DIR:-/tmp/CunningPaperDerivedData}" build
```

Expected: BUILD SUCCEEDED before UI edits, giving you a clean baseline.

- [ ] **Step 3: Implement the editor surface changes**

Apply these targeted updates:

`CunningPaper/Editor/Cards/CardListView.swift`

```swift
VStack(alignment: .leading, spacing: 5) {
    Text(card.listHeadline)
        .font(.body.weight(isSelected ? .semibold : .medium))
        .lineLimit(1)

    Text(card.listSubheadline)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)

    Text(card.paragraphCountLabel)
        .font(.caption2)
        .foregroundStyle(.tertiary)
}
```

`CunningPaper/Editor/Cards/CardDetailView.swift`

```swift
VStack(alignment: .leading, spacing: 0) {
    Text(card.paragraphCountLabel)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 10)

    CardBodyTextView(
        text: textBinding(for: \.body),
        onActiveParagraphChange: onActiveParagraphChange
    )
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
}
```

`CunningPaper/Editor/Cards/CardStudioView.swift`

```swift
CardPreviewPane(
    paragraphs: selectedCard.paragraphs,
    activeParagraphIndex: activeParagraphIndex
)
```

`CunningPaper/Editor/Cards/CardPreviewPane.swift`

```swift
CardDisplayView(
    paragraphs: previewWindowParagraphs,
    activeIndex: 0,
    fontSize: 20,
    highlightCurrentParagraph: false,
    stackSpacing: 10,
    paragraphLineSpacing: 20 * 0.16,
    horizontalPadding: 18,
    verticalPadding: 16,
    paragraphOpacities: previewParagraphOpacities
)
```

`CunningPaper/Editor/Cards/CardEmptyStateView.swift`

```swift
private let sampleCards: [String] = [
    "I build products by reducing ambiguity.\nI care about the edges, not just the happy path.",
    "The last major project focused on a dense operations UI.\nI restructured the flow around decisions rather than raw data.",
    "I prefer teams that value speed and taste together.\nShipping is better when the structure is clear from the start."
]

let card = CardModel(body: "", order: nextOrder)
let card = CardModel(body: sample, order: startOrder + Double(index))
```

- [ ] **Step 4: Rebuild and manually verify the editor**

Run:

```bash
xcodebuild -project "$PWD/CunningPaper.xcodeproj" -scheme CunningPaper -destination 'platform=macOS' -derivedDataPath "${DERIVED_DATA_DIR:-/tmp/CunningPaperDerivedData}" build
```

Expected: BUILD SUCCEEDED.

Then manually verify:

- create a blank card from the list footer and from the empty state
- confirm there is no title field in the detail pane
- confirm list rows show the derived two-line summary and paragraph count
- confirm the preview pane renders body paragraphs only

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Editor/Cards/CardListView.swift CunningPaper/Editor/Cards/CardDetailView.swift CunningPaper/Editor/Cards/CardStudioView.swift CunningPaper/Editor/Cards/CardPreviewPane.swift CunningPaper/Editor/Cards/CardEmptyStateView.swift
git commit -m "refactor: make editor cards body-first"
```

### Task 3: Remove Overlay Search and Title-Specific Overlay Wiring

**Files:**
- Modify: `CunningPaper/Overlay/CardDisplayView.swift`
- Modify: `CunningPaper/Overlay/OverlayView.swift`
- Modify: `CunningPaper/System/HotkeyManager.swift`
- Modify: `CunningPaper/Editor/Preferences/PreferencesView.swift`
- Modify: `CunningPaper.xcodeproj/project.pbxproj`
- Delete: `CunningPaper/Overlay/SearchPanelView.swift`
- Test: manual overlay verification

- [ ] **Step 1: Add the failing tests or static checks for removed search references**

Because there are no overlay interaction tests yet, create a static verification step by searching for references that must disappear:

```bash
rg -n "case search|\\.search\\b|SearchPanelView|titleScale|titleOpacity|let title: String|displayTitle" "$PWD/CunningPaper" -S
```

Expected before implementation: matches in overlay, hotkey, preferences, and search panel files.

- [ ] **Step 2: Run the static check and confirm the old paths still exist**

Run the same command:

```bash
rg -n "case search|\\.search\\b|SearchPanelView|titleScale|titleOpacity|let title: String|displayTitle" "$PWD/CunningPaper" -S
```

Expected: non-empty output proving the old search/title plumbing is still present.

- [ ] **Step 3: Implement the overlay cleanup**

Apply these changes:

`CunningPaper/Overlay/CardDisplayView.swift`

```swift
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .clipped()
    }
}
```

`CunningPaper/Overlay/OverlayView.swift`

```swift
enum ActivePanel: Equatable {
    case none
    case jump
}

CardDisplayView(
    paragraphs: currentCard?.paragraphs ?? ["No cards yet"],
    activeIndex: activeParagraphIndex,
    fontSize: prefs?.fontSize ?? 24,
    highlightCurrentParagraph: prefs?.highlightCurrentParagraph ?? true
)

case .jump:
    activePanel = .jump
```

`CunningPaper/System/HotkeyManager.swift`

```swift
enum HotkeyAction: String, CaseIterable {
    case next
    case prev
    case jump
    case nextLine
    case prevLine
    case toggle
}

extension KeyboardShortcuts.Name {
    static let next = Self("cunningPaper.next")
    static let prev = Self("cunningPaper.prev")
    static let jump = Self("cunningPaper.jump")
    static let nextLine = Self("cunningPaper.nextLine")
    static let prevLine = Self("cunningPaper.prevLine")
    static let toggle = Self("cunningPaper.toggle")
}
```

`CunningPaper/Editor/Preferences/PreferencesView.swift`

```swift
VStack(alignment: .leading, spacing: 10) {
    shortcutRow("Next Card", name: .next)
    shortcutRow("Previous Card", name: .prev)
    shortcutRow("Jump", name: .jump)
    shortcutRow("Next Paragraph", name: .nextLine)
    shortcutRow("Previous Paragraph", name: .prevLine)
    shortcutRow("Toggle Overlay", name: .toggle)
}
```

Then delete `CunningPaper/Overlay/SearchPanelView.swift` and remove its references from `CunningPaper.xcodeproj/project.pbxproj`.

- [ ] **Step 4: Re-run static checks and build**

Run:

```bash
rg -n "case search|\\.search\\b|SearchPanelView|titleScale|titleOpacity|let title: String|displayTitle" "$PWD/CunningPaper" -S
xcodebuild -project "$PWD/CunningPaper.xcodeproj" -scheme CunningPaper -destination 'platform=macOS' -derivedDataPath "${DERIVED_DATA_DIR:-/tmp/CunningPaperDerivedData}" build
```

Expected:

- `rg` returns no matches in app source
- `xcodebuild` reports BUILD SUCCEEDED

Then manually verify the overlay:

- title text is gone from the overlay
- jump still opens
- next/previous card and paragraph hotkeys still work
- there is no search command in preferences

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Overlay/CardDisplayView.swift CunningPaper/Overlay/OverlayView.swift CunningPaper/System/HotkeyManager.swift CunningPaper/Editor/Preferences/PreferencesView.swift CunningPaper.xcodeproj/project.pbxproj
git add -u CunningPaper/Overlay/SearchPanelView.swift
git commit -m "refactor: remove overlay card search"
```

### Task 4: Final Verification and Cleanup

**Files:**
- Modify: `docs/superpowers/plans/2026-04-01-card-title-removal.md` only if verification notes need correction
- Test: full project verification

- [ ] **Step 1: Run the full relevant test suite**

Run:

```bash
xcodebuild test -project "$PWD/CunningPaper.xcodeproj" -scheme CunningPaper -destination 'platform=macOS' -derivedDataPath "${DERIVED_DATA_DIR:-/tmp/CunningPaperDerivedData}" -only-testing:CunningPaperTests/ModelTests -only-testing:CunningPaperTests/MigrationServiceTests
```

Expected: TEST SUCCEEDED.

- [ ] **Step 2: Run one final source scan for removed concepts**

Run:

```bash
rg -n "displayTitle|Card title|SearchPanelView|cunningPaper\\.search|titleScale|titleOpacity" "$PWD/CunningPaper" -S
```

Expected: no matches.

- [ ] **Step 3: Run the app build used for handoff**

Run:

```bash
xcodebuild -project "$PWD/CunningPaper.xcodeproj" -scheme CunningPaper -destination 'platform=macOS' -derivedDataPath "${DERIVED_DATA_DIR:-/tmp/CunningPaperDerivedData}" build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Record manual verification results**

Capture these outcomes in the final handoff note:

```text
- Existing cards still load and keep body/order metadata.
- New cards are body-only.
- List uses derived first-word and first-line summaries.
- Preview and overlay render paragraphs only.
- Overlay search and search shortcut UI are removed.
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "test: verify body-first card flow"
```
