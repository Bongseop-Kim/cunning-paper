# Card Editor Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the card editing tab into a reading-studio workflow with a persistent preview pane, denser list scanning, and a calmer writing surface.

**Architecture:** Keep the existing SwiftData model and overall tab structure, but replace the card-tab split view with a dedicated `CardStudioView`. Add a compact preview component that reuses the overlay reading language, then refactor the list, detail, and empty states around that composition. Preserve native macOS behavior where it helps usability, and add only lightweight view-model-free helpers when the UI needs computed presentation data.

**Tech Stack:** SwiftUI, SwiftData, XCTest, Xcode scheme `CunningPaper`

---

## File Structure

- Create: `CunningPaper/Editor/Cards/CardStudioView.swift`
  - Compose the full card-tab workspace from the existing list and detail surfaces.
- Create: `CunningPaper/Editor/Cards/CardPreviewPane.swift`
  - Render a compact overlay-like preview for the selected card.
- Modify: `CunningPaper/Editor/EditorView.swift`
  - Replace the direct card-tab split layout with `CardStudioView`.
- Modify: `CunningPaper/Editor/Cards/CardListView.swift`
  - Redesign row hierarchy, selection treatment, and create action presentation.
- Modify: `CunningPaper/Editor/Cards/CardDetailView.swift`
  - Add a metadata header, refine spacing/typography, and demote destructive actions.
- Modify: `CunningPaper/Editor/Cards/CardEmptyStateView.swift`
  - Rebalance CTA hierarchy and rewrite copy for the new studio tone.
- Modify: `CunningPaper/Data/CardModel.swift`
  - Add compact presentation helpers needed by the redesigned list and detail header.
- Modify: `CunningPaperTests/ModelTests.swift`
  - Add tests for the new `CardModel` presentation helpers.

## Shared Test Command

Use this command after each task that touches compileable app code:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected success tail:

```text
** TEST SUCCEEDED **
```

## Task 1: Add Card Presentation Helpers

**Files:**
- Modify: `CunningPaper/Data/CardModel.swift`
- Test: `CunningPaperTests/ModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Add these tests to `CunningPaperTests/ModelTests.swift`:

```swift
func testCardModelPreviewLineUsesFirstParagraph() {
    let card = CardModel(title: "T", body: "first line\nsecond line")
    XCTAssertEqual(card.previewLine, "first line")
}

func testCardModelPreviewLineFallsBackWhenBodyEmpty() {
    let card = CardModel(title: "T", body: "")
    XCTAssertEqual(card.previewLine, "Empty card")
}

func testCardModelParagraphCountMatchesParagraphs() {
    let card = CardModel(title: "T", body: "one\n\ntwo")
    XCTAssertEqual(card.paragraphCount, 2)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ModelTests
```

Expected:

```text
Value of type 'CardModel' has no member 'previewLine'
Value of type 'CardModel' has no member 'paragraphCount'
```

- [ ] **Step 3: Write the minimal implementation**

Update `CunningPaper/Data/CardModel.swift`:

```swift
var previewLine: String {
    paragraphs.first ?? "Empty card"
}

var paragraphCount: Int {
    paragraphs.count
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ModelTests
```

Expected:

```text
Test Suite 'ModelTests' passed
```

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Data/CardModel.swift CunningPaperTests/ModelTests.swift
git commit -m "feat: add card editor presentation helpers"
```

## Task 2: Introduce CardPreviewPane

**Files:**
- Create: `CunningPaper/Editor/Cards/CardPreviewPane.swift`
- Modify: `CunningPaper/Overlay/CardDisplayView.swift`

- [ ] **Step 1: Write the failing integration target by referencing the new view**

Create `CunningPaper/Editor/Cards/CardPreviewPane.swift` with this stub that will not compile until `CardDisplayView` gets the new initializer usage wired correctly:

```swift
import SwiftUI

struct CardPreviewPane: View {
    let title: String
    let paragraphs: [String]

    var body: some View {
        CardDisplayView(
            title: title,
            paragraphs: paragraphs,
            activeIndex: 0,
            fontSize: 20,
            highlightCurrentParagraph: true
        )
    }
}
```

- [ ] **Step 2: Run build-focused tests to verify the new file is included and compiles in isolation**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ModelTests
```

Expected:

```text
Compile succeeds but preview styling is still incomplete
```

- [ ] **Step 3: Replace the stub with the real preview implementation**

Replace `CunningPaper/Editor/Cards/CardPreviewPane.swift` with:

```swift
import SwiftUI

struct CardPreviewPane: View {
    let title: String
    let paragraphs: [String]

    private var previewParagraphs: [String] {
        paragraphs.isEmpty ? ["Start writing to see the reading preview."] : paragraphs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            CardDisplayView(
                title: title,
                paragraphs: previewParagraphs,
                activeIndex: 0,
                fontSize: 20,
                highlightCurrentParagraph: true
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
```

- [ ] **Step 4: Tune `CardDisplayView` for reuse in the editor preview**

Update `CunningPaper/Overlay/CardDisplayView.swift`:

```swift
VStack(alignment: .leading, spacing: 10) {
    if !title.isEmpty {
        Text(title)
            .font(.system(size: fontSize * 0.58, weight: .semibold))
            .foregroundStyle(.white.opacity(0.68))
            .lineLimit(1)
    }

    ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
        Text(paragraph)
            .font(.system(size: fontSize))
            .lineSpacing(fontSize * 0.16)
            .foregroundStyle(foregroundColor(for: index))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
.padding(.horizontal, 18)
.padding(.vertical, 16)
```

- [ ] **Step 5: Run test to verify the app still builds**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 6: Commit**

```bash
git add CunningPaper/Editor/Cards/CardPreviewPane.swift CunningPaper/Overlay/CardDisplayView.swift
git commit -m "feat: add card editor preview pane"
```

## Task 3: Create CardStudioView and Rewire the Card Tab

**Files:**
- Create: `CunningPaper/Editor/Cards/CardStudioView.swift`
- Modify: `CunningPaper/Editor/EditorView.swift`

- [ ] **Step 1: Write the failing composition by referencing `CardStudioView` from `EditorView`**

Update the `.cards` branch in `CunningPaper/Editor/EditorView.swift` to:

```swift
case .cards:
    CardStudioView(selectedCardID: $selectedCardID)
```

Run before creating the file so the compiler fails with:

```text
Cannot find 'CardStudioView' in scope
```

- [ ] **Step 2: Add the minimal `CardStudioView`**

Create `CunningPaper/Editor/Cards/CardStudioView.swift`:

```swift
import SwiftUI

struct CardStudioView: View {
    @Binding var selectedCardID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            CardListView(selectedCardID: $selectedCardID)
                .frame(width: 232)

            Divider()

            Group {
                if let selectedCardID {
                    CardDetailView(cardID: selectedCardID) {
                        self.selectedCardID = nil
                    }
                } else {
                    CardEmptyStateView { newID in
                        selectedCardID = newID
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
```

- [ ] **Step 3: Expand `CardStudioView` into the real studio layout**

Replace the right-side `Group` in `CunningPaper/Editor/Cards/CardStudioView.swift`:

```swift
Group {
    if let selectedCardID {
        VStack(spacing: 0) {
            CardPreviewPane(title: selectedCard.title, paragraphs: selectedCard.paragraphs)
                .frame(height: 208)
                .padding(.horizontal, 28)
                .padding(.top, 24)
                .padding(.bottom, 20)

            CardDetailView(cardID: selectedCardID) {
                self.selectedCardID = nil
            }
        }
    } else {
        CardEmptyStateView { newID in
            selectedCardID = newID
        }
    }
}
```

and add the supporting query/computed property at the top of the file:

```swift
@Query(sort: \CardModel.order) private var cards: [CardModel]

private var selectedCard: CardModel {
    cards.first(where: { $0.id == selectedCardID }) ?? CardModel(title: "", body: "")
}
```

- [ ] **Step 4: Add a restrained transition to the right pane**

In `CunningPaper/Editor/Cards/CardStudioView.swift`, add:

```swift
.animation(.easeInOut(duration: 0.16), value: selectedCardID)
```

to the right-side `Group`.

- [ ] **Step 5: Run test to verify the new composition compiles**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 6: Commit**

```bash
git add CunningPaper/Editor/EditorView.swift CunningPaper/Editor/Cards/CardStudioView.swift
git commit -m "feat: introduce card studio layout"
```

## Task 4: Redesign CardListView for Scan Speed

**Files:**
- Modify: `CunningPaper/Editor/Cards/CardListView.swift`

- [ ] **Step 1: Replace the current row body with richer presentation data**

Update the `ForEach` body in `CunningPaper/Editor/Cards/CardListView.swift` to:

```swift
ForEach(cards) { card in
    HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 1)
            .fill(selectedCardID == card.id ? Color.accentColor : .clear)
            .frame(width: 3)

        VStack(alignment: .leading, spacing: 5) {
            Text(card.displayTitle)
                .font(.body.weight(selectedCardID == card.id ? .semibold : .medium))
                .lineLimit(1)

            Text(card.previewLine)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text("\(card.paragraphCount) paragraphs")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
    .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(selectedCardID == card.id ? Color.accentColor.opacity(0.10) : .clear)
    )
    .tag(card.id)
}
```

- [ ] **Step 2: Reduce default sidebar styling so the custom hierarchy is visible**

In `CunningPaper/Editor/Cards/CardListView.swift`, update the list modifiers:

```swift
List(selection: $selectedCardID) { ... }
    .listStyle(.sidebar)
    .scrollContentBackground(.hidden)
    .background(Color.clear)
```

- [ ] **Step 3: Restyle the create action as a tool action**

Replace the bottom button with:

```swift
HStack {
    Button {
        addBlankCard()
    } label: {
        Label("New Card", systemImage: "plus")
            .font(.subheadline.weight(.semibold))
    }
    .buttonStyle(.borderless)

    Spacer()
}
.padding(.horizontal, 12)
.padding(.vertical, 10)
.background(.bar)
```

- [ ] **Step 4: Run tests to verify the redesigned list compiles**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Editor/Cards/CardListView.swift
git commit -m "feat: redesign card list hierarchy"
```

## Task 5: Refine CardDetailView Into a Writing Surface

**Files:**
- Modify: `CunningPaper/Editor/Cards/CardDetailView.swift`

- [ ] **Step 1: Add a metadata header above the title**

Insert this helper into `CunningPaper/Editor/Cards/CardDetailView.swift`:

```swift
private var metaLine: String {
    guard let card else { return "" }
    return "\(card.paragraphCount) paragraphs"
}
```

and add this view above the title field:

```swift
Text(metaLine)
    .font(.caption.weight(.semibold))
    .foregroundStyle(.secondary)
    .textCase(.uppercase)
    .padding(.horizontal, 24)
    .padding(.top, 24)
```

- [ ] **Step 2: Rework title and body spacing**

Update the content stack in `CunningPaper/Editor/Cards/CardDetailView.swift`:

```swift
VStack(alignment: .leading, spacing: 0) {
    TextField(
        "Card title",
        text: Binding(
            get: { card.title },
            set: {
                card.title = $0
                card.updatedAt = Date()
                try? context.save()
            }
        )
    )
    .textFieldStyle(.plain)
    .font(.system(size: 28, weight: .semibold))
    .padding(.horizontal, 24)
    .padding(.top, 8)
    .padding(.bottom, 18)

    TextEditor(
        text: Binding(
            get: { card.body },
            set: {
                card.body = $0
                card.updatedAt = Date()
                try? context.save()
            }
        )
    )
    .font(.body)
    .padding(.horizontal, 18)
    .padding(.vertical, 16)
}
```

- [ ] **Step 3: Move delete into a lower-emphasis menu action**

Replace the bottom destructive button block in `CunningPaper/Editor/Cards/CardDetailView.swift` with:

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Menu {
            Button(role: .destructive) {
                context.delete(card)
                try? context.save()
                onDelete()
            } label: {
                Label("Delete Card", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
```

- [ ] **Step 4: Run tests to verify the refactor compiles**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Editor/Cards/CardDetailView.swift
git commit -m "feat: refine card detail writing surface"
```

## Task 6: Rewrite the Empty State for the Studio Flow

**Files:**
- Modify: `CunningPaper/Editor/Cards/CardEmptyStateView.swift`

- [ ] **Step 1: Make first-card creation the primary CTA**

Replace the current body stack in `CunningPaper/Editor/Cards/CardEmptyStateView.swift` with:

```swift
VStack(alignment: .center, spacing: 18) {
    Text("Start the next card")
        .font(.title3.weight(.semibold))

    Text("Create a card and see its reading preview as you write.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 340)

    VStack(spacing: 10) {
        Button("Create First Card", action: addBlankCard)
            .buttonStyle(.borderedProminent)

        Button("Add Samples", action: addSamples)
            .buttonStyle(.borderless)
    }
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
.padding(32)
```

- [ ] **Step 2: Remove old utility-oriented copy**

Delete these strings from `CunningPaper/Editor/Cards/CardEmptyStateView.swift`:

```swift
"Select a card or create one"
"Start with a blank card or seed the editor with sample content."
"Blank Card"
```

and ensure only the new copy from Step 1 remains.

- [ ] **Step 3: Run tests to verify the empty state compiles**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 4: Commit**

```bash
git add CunningPaper/Editor/Cards/CardEmptyStateView.swift
git commit -m "feat: refine card editor empty state"
```

## Task 7: Final Integration Pass

**Files:**
- Modify: `CunningPaper/Editor/Cards/CardStudioView.swift`
- Modify: `CunningPaper/Editor/Cards/CardPreviewPane.swift`
- Modify: `CunningPaper/Editor/Cards/CardDetailView.swift`
- Modify: `CunningPaper/Editor/Cards/CardListView.swift`

- [ ] **Step 1: Align pane spacing and backgrounds**

Apply this layout polish across the studio views:

```swift
.background(Color(nsColor: .windowBackgroundColor))
```

Use it on the right-side studio surface and keep the preview padding consistent:

```swift
.padding(.horizontal, 28)
.padding(.top, 24)
.padding(.bottom, 20)
```

- [ ] **Step 2: Ensure new-card creation leaves the user in writing mode**

After `addBlankCard()` saves in `CunningPaper/Editor/Cards/CardListView.swift`, keep:

```swift
selectedCardID = card.id
```

and verify `CardDetailView` still opens immediately for the created card.

- [ ] **Step 3: Run the full test suite**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 4: Manual verification**

Launch the app and confirm:

```text
1. Cards tab shows list on the left and preview + editor on the right.
2. Selecting a card updates the preview immediately.
3. New Card opens directly into the writing surface.
4. Empty state promotes Create First Card over Add Samples.
5. Delete is available from the toolbar/menu, not the bottom edge.
```

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Editor/EditorView.swift \
  CunningPaper/Editor/Cards/CardStudioView.swift \
  CunningPaper/Editor/Cards/CardPreviewPane.swift \
  CunningPaper/Editor/Cards/CardListView.swift \
  CunningPaper/Editor/Cards/CardDetailView.swift \
  CunningPaper/Editor/Cards/CardEmptyStateView.swift \
  CunningPaper/Data/CardModel.swift \
  CunningPaperTests/ModelTests.swift
git commit -m "feat: redesign card editor as reading studio"
```

## Self-Review

### Spec coverage

- Reading-studio structure: covered by Task 3.
- Compact preview pane: covered by Task 2 and Task 3.
- Denser list scanning and stronger selection state: covered by Task 4.
- Refined writing surface and demoted destructive action: covered by Task 5.
- Primary empty-state CTA and revised copy: covered by Task 6.
- Final integration polish: covered by Task 7.

No spec gaps found for the approved card-editor scope.

### Placeholder scan

- No `TODO`, `TBD`, or deferred implementation markers remain.
- Each code-changing step includes explicit code or exact commands.
- Test and commit steps are concrete.

### Type consistency

- `previewLine` and `paragraphCount` are defined in Task 1 and reused consistently later.
- `CardStudioView` and `CardPreviewPane` names match the design spec.
- The preview always consumes `title` and `paragraphs`, consistent with `CardDisplayView`.
