# Quick Positions Preset Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add compact preset previews to Quick Positions cards, using a top thumbnail layout when the preview area is wide enough and a side icon layout when the preview area is tighter.

**Architecture:** Keep `QuickPositionBar` as the composition root for the grid, but move preview layout decisions into `ZonePickerPresentation` so the card can render a small, testable view model instead of embedding sizing heuristics inline. Introduce a focused SwiftUI preview subview for drawing the monitor outline and selected preset rectangle, then update the existing card layout to combine preview, label, saved badge, active state, and delete affordance without changing the preset ordering behavior.

**Tech Stack:** SwiftUI, XCTest, existing `ZonePreset`/`ZonePickerPresentation` helpers

---

## File Structure

- Modify: `CunningPaper/Editor/Position/ZonePickerPresentation.swift`
  - Add preview layout decision helpers and compact preview sizing constants.
- Modify: `CunningPaper/Editor/Position/QuickPositionBar.swift`
  - Replace text-only card content with adaptive preview + label composition while preserving current selection and delete behaviors.
- Create: `CunningPaper/Editor/Position/PresetPreviewView.swift`
  - Draw the monitor frame and selected preset rectangle, switching between top-thumbnail and side-icon arrangements based on available space.
- Modify: `CunningPaperTests/ZonePickerPresentationTests.swift`
  - Add unit tests for preview layout selection and keep display ordering coverage intact.

### Task 1: Define and test preview layout selection

**Files:**
- Modify: `CunningPaper/Editor/Position/ZonePickerPresentation.swift`
- Test: `CunningPaperTests/ZonePickerPresentationTests.swift`

- [ ] **Step 1: Write the failing tests for preview layout selection**

Add these tests to `CunningPaperTests/ZonePickerPresentationTests.swift`:

```swift
func testQuickPresetPreviewUsesTopLayoutForWidePreviewArea() {
    let layout = ZonePickerPresentation.quickPresetPreviewLayout(
        availableWidth: 118,
        availableHeight: 72
    )

    XCTAssertEqual(layout, .topThumbnail)
}

func testQuickPresetPreviewUsesSideLayoutForTightPreviewArea() {
    let layout = ZonePickerPresentation.quickPresetPreviewLayout(
        availableWidth: 92,
        availableHeight: 72
    )

    XCTAssertEqual(layout, .sideIcon)
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests
```

Expected:

```text
error: type 'ZonePickerPresentation' has no member 'quickPresetPreviewLayout'
```

- [ ] **Step 3: Add a focused layout enum and decision helper**

Update `CunningPaper/Editor/Position/ZonePickerPresentation.swift` with the new helper:

```swift
import CoreGraphics

enum QuickPresetPreviewLayout {
    case topThumbnail
    case sideIcon
}

enum ZonePickerPresentation {
    static let quickPresetPreviewMinimumHeight: CGFloat = 34

    static func quickPresetPreviewLayout(
        availableWidth: CGFloat,
        availableHeight: CGFloat
    ) -> QuickPresetPreviewLayout {
        let normalizedHeight = max(availableHeight, quickPresetPreviewMinimumHeight)
        let widthRatio = availableWidth / normalizedHeight

        if widthRatio >= 1.45 {
            return .topThumbnail
        }

        return .sideIcon
    }

    static let quickPresets: [ZonePreset] = [
        .init(id: "full", label: "Full Screen", x: 0, y: 0, w: 1, h: 1, builtIn: true),
        .init(id: "left", label: "Left Half", x: 0, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "right", label: "Right Half", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "top", label: "Top Half", x: 0, y: 0, w: 1, h: 0.5, builtIn: true),
        .init(id: "bottom", label: "Bottom Half", x: 0, y: 0.5, w: 1, h: 0.5, builtIn: true),
        .init(id: "center", label: "Centered", x: 0.2, y: 0.2, w: 0.6, h: 0.6, builtIn: true),
    ]
```

- [ ] **Step 4: Run the tests to verify they pass**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests
```

Expected:

```text
Test Suite 'ZonePickerPresentationTests' passed
```

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Editor/Position/ZonePickerPresentation.swift CunningPaperTests/ZonePickerPresentationTests.swift
git commit -m "test: add quick position preview layout rules"
```

### Task 2: Build the reusable preset preview view

**Files:**
- Create: `CunningPaper/Editor/Position/PresetPreviewView.swift`
- Modify: `CunningPaper/Editor/Position/ZonePickerPresentation.swift`
- Test: `CunningPaperTests/ZonePickerPresentationTests.swift`

- [ ] **Step 1: Write the failing tests for preview sizing constants**

Add these tests to `CunningPaperTests/ZonePickerPresentationTests.swift`:

```swift
func testQuickPresetPreviewFrameUsesExpectedTopThumbnailSize() {
    let size = ZonePickerPresentation.quickPresetPreviewFrame(for: .topThumbnail)

    XCTAssertEqual(size.width, 56)
    XCTAssertEqual(size.height, 34)
}

func testQuickPresetPreviewFrameUsesExpectedSideIconSize() {
    let size = ZonePickerPresentation.quickPresetPreviewFrame(for: .sideIcon)

    XCTAssertEqual(size.width, 34)
    XCTAssertEqual(size.height, 26)
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests
```

Expected:

```text
error: type 'ZonePickerPresentation' has no member 'quickPresetPreviewFrame'
```

- [ ] **Step 3: Add preview sizing helper and create the drawing view**

Extend `CunningPaper/Editor/Position/ZonePickerPresentation.swift`:

```swift
static func quickPresetPreviewFrame(for layout: QuickPresetPreviewLayout) -> CGSize {
    switch layout {
    case .topThumbnail:
        return CGSize(width: 56, height: 34)
    case .sideIcon:
        return CGSize(width: 34, height: 26)
    }
}
```

Create `CunningPaper/Editor/Position/PresetPreviewView.swift`:

```swift
import SwiftUI

struct PresetPreviewView: View {
    let preset: ZonePreset
    let layout: QuickPresetPreviewLayout
    let isActive: Bool

    var body: some View {
        let frame = ZonePickerPresentation.quickPresetPreviewFrame(for: layout)

        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )

            GeometryReader { proxy in
                let insetX = proxy.size.width * 0.06
                let insetY = proxy.size.height * 0.10
                let width = proxy.size.width - (insetX * 2)
                let height = proxy.size.height - (insetY * 2)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isActive ? Color.accentColor : Color.accentColor.opacity(0.65))
                    .frame(width: width * preset.w, height: height * preset.h)
                    .position(
                        x: insetX + (width * preset.x) + ((width * preset.w) / 2),
                        y: insetY + (height * preset.y) + ((height * preset.h) / 2)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .frame(width: frame.width, height: frame.height)
        .accessibilityHidden(true)
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests
```

Expected:

```text
Test Suite 'ZonePickerPresentationTests' passed
```

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Editor/Position/ZonePickerPresentation.swift CunningPaper/Editor/Position/PresetPreviewView.swift CunningPaper.xcodeproj/project.pbxproj CunningPaperTests/ZonePickerPresentationTests.swift
git commit -m "feat: add quick position preset preview view"
```

### Task 3: Integrate adaptive preview cards into QuickPositionBar

**Files:**
- Modify: `CunningPaper/Editor/Position/QuickPositionBar.swift`
- Modify: `CunningPaper/Editor/Position/PresetPreviewView.swift`
- Test: `CunningPaperTests/ZonePickerPresentationTests.swift`

- [ ] **Step 1: Write the failing test for the layout threshold used by cards**

Add this test to `CunningPaperTests/ZonePickerPresentationTests.swift`:

```swift
func testQuickPresetPreviewLayoutTreatsCurrentCardWidthAsTopThumbnail() {
    let layout = ZonePickerPresentation.quickPresetPreviewLayout(
        availableWidth: 110 - 24,
        availableHeight: 72
    )

    XCTAssertEqual(layout, .sideIcon)
}
```

Then update the expected value to `.topThumbnail` only after confirming the actual card content width the UI should use. This test exists to force the implementation to codify the threshold instead of leaving it implicit.

- [ ] **Step 2: Run the tests to verify they fail or expose the wrong threshold**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests/testQuickPresetPreviewLayoutTreatsCurrentCardWidthAsTopThumbnail
```

Expected:

```text
Assertion failed because the threshold does not yet match the intended card content width
```

- [ ] **Step 3: Replace the card label stack with adaptive preview composition**

Update `CunningPaper/Editor/Position/QuickPositionBar.swift`:

```swift
import SwiftUI

struct QuickPositionBar: View {
    let presets: [ZonePreset]
    let activePresetKey: String?
    let onSelect: (ZonePreset) -> Void
    let onDelete: ((ZonePreset) -> Void)?

    private let cardContentHeight: CGFloat = 72

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 10, alignment: .leading)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Positions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(presets) { preset in
                    let isActive = activePresetKey?.hasSuffix(":\(preset.id)") == true

                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(backgroundColor(for: preset, isActive: isActive))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(borderColor(for: preset, isActive: isActive), lineWidth: 1)
                            )

                        Button {
                            onSelect(preset)
                        } label: {
                            GeometryReader { proxy in
                                let contentWidth = max(proxy.size.width - 24, 0)
                                let layout = ZonePickerPresentation.quickPresetPreviewLayout(
                                    availableWidth: contentWidth,
                                    availableHeight: cardContentHeight
                                )

                                quickPositionContent(
                                    for: preset,
                                    layout: layout,
                                    isActive: isActive
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .frame(minHeight: 72)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        if !preset.builtIn, let onDelete {
                            Button {
                                onDelete(preset)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22, height: 22)
                                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.95), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(6)
                            .accessibilityLabel("Delete \(preset.label)")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func quickPositionContent(
        for preset: ZonePreset,
        layout: QuickPresetPreviewLayout,
        isActive: Bool
    ) -> some View {
        switch layout {
        case .topThumbnail:
            VStack(alignment: .leading, spacing: 6) {
                PresetPreviewView(preset: preset, layout: layout, isActive: isActive)
                quickPositionLabelBlock(for: preset)
            }

        case .sideIcon:
            HStack(alignment: .center, spacing: 10) {
                PresetPreviewView(preset: preset, layout: layout, isActive: isActive)
                quickPositionLabelBlock(for: preset)
            }
        }
    }

    private func quickPositionLabelBlock(for preset: ZonePreset) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !preset.builtIn {
                Text("Saved")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(preset.label)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

- [ ] **Step 4: Run targeted tests and build verification**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests
```

Then run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected:

```text
** TEST SUCCEEDED **
```

- [ ] **Step 5: Commit**

```bash
git add CunningPaper/Editor/Position/QuickPositionBar.swift CunningPaper/Editor/Position/PresetPreviewView.swift CunningPaper/Editor/Position/ZonePickerPresentation.swift CunningPaperTests/ZonePickerPresentationTests.swift
git commit -m "feat: add adaptive quick position previews"
```

### Task 4: Polish spacing, accessibility, and regression coverage

**Files:**
- Modify: `CunningPaper/Editor/Position/QuickPositionBar.swift`
- Modify: `CunningPaperTests/ZonePickerPresentationTests.swift`

- [ ] **Step 1: Write a regression test to preserve custom-first display ordering**

Keep or extend `CunningPaperTests/ZonePickerPresentationTests.swift` with:

```swift
func testDisplayPresetsKeepsNewestCustomPresetAheadOfBuiltIns() {
    let custom = [
        ZonePreset(id: "older", label: "Older", x: 0, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: nil, monitorName: nil),
        ZonePreset(id: "newer", label: "Newer", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: nil, monitorName: nil)
    ]

    let displayed = ZonePickerPresentation.displayPresets(customPresets: custom)

    XCTAssertEqual(displayed.map(\.id), ["newer", "older", "full", "left", "right", "top", "bottom", "center"])
}
```

- [ ] **Step 2: Run the regression test to confirm current behavior stays intact**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests/testDisplayPresetsKeepsNewestCustomPresetAheadOfBuiltIns
```

Expected:

```text
Test Case '-[CunningPaperTests.ZonePickerPresentationTests testDisplayPresetsKeepsNewestCustomPresetAheadOfBuiltIns]' passed
```

- [ ] **Step 3: Final UI polish pass**

Adjust `CunningPaper/Editor/Position/QuickPositionBar.swift` to keep the card readable after the preview is introduced:

```swift
private func quickPositionLabelBlock(for preset: ZonePreset) -> some View {
    VStack(alignment: .leading, spacing: 3) {
        if !preset.builtIn {
            Text("Saved")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }

        Text(preset.label)
            .font(.subheadline.weight(.medium))
            .lineLimit(2)
            .minimumScaleFactor(0.9)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .accessibilityElement(children: .combine)
}
```

This preserves readability for longer custom labels without changing the delete button affordance or active-card visual treatment.

- [ ] **Step 4: Run the full test suite**

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
git add CunningPaper/Editor/Position/QuickPositionBar.swift CunningPaperTests/ZonePickerPresentationTests.swift
git commit -m "chore: polish quick position preview cards"
```

## Self-Review

- Spec coverage:
  - Adaptive preview layouts are covered in Tasks 1 through 3.
  - Built-in 6 presets plus custom presets sharing the same visual language are covered in Tasks 2 through 4.
  - Existing ordering, selection, saved badge, and delete behaviors are preserved by Tasks 3 and 4.
- Placeholder scan:
  - No `TODO`, `TBD`, or unresolved “handle later” language remains.
  - Every code-changing step includes explicit code or commands.
- Type consistency:
  - `QuickPresetPreviewLayout`, `quickPresetPreviewLayout`, `quickPresetPreviewFrame`, and `PresetPreviewView` are introduced once and reused consistently.

## Notes

- The `.superpowers/` directory is currently untracked in this workspace. Do not include it in implementation commits.
- This plan deliberately avoids snapshot/UI automation because the current test suite is XCTest-only and the preview layout decision can be validated with focused unit tests.
