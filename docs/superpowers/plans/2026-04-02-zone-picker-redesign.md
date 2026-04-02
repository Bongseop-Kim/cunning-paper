# Zone Picker Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reframe the Position tab as a fast monitor-positioning workflow centered on immediate placement, quick built-in actions, and secondary saved-position management.

**Architecture:** Keep the existing `ZonePickerState`, `GridMath`, and SwiftData persistence model, but move the UI away from the current split-view preset browser into a vertical composition built around `GridCanvasView`. Introduce a small presentation helper layer for position summaries and built-in quick actions so the new header and action bar can stay declarative and testable.

**Tech Stack:** SwiftUI, SwiftData, XCTest, Xcode scheme `CunningPaper`

---

## File Structure

- Create: `CunningPaper/Editor/Position/ZonePickerPresentation.swift`
  - Hold quick-action definitions, filtering helpers, and human-readable position summaries for the position tab.
- Create: `CunningPaper/Editor/Position/PositionHeaderView.swift`
  - Render the title, instructional copy, current monitor metadata, and current position summary.
- Create: `CunningPaper/Editor/Position/QuickPositionBar.swift`
  - Render built-in placement actions as immediate buttons beneath the canvas.
- Create: `CunningPaper/Editor/Position/SavedPositionsView.swift`
  - Render save-current-position controls and saved custom positions for the active monitor.
- Modify: `CunningPaper/Editor/Position/ZonePickerView.swift`
  - Replace `HSplitView` composition with the new header/canvas/action/save workflow.
- Modify: `CunningPaper/Editor/Position/GridCanvasView.swift`
  - Strengthen selection feedback and expose the canvas as the primary visual anchor.
- Delete: `CunningPaper/Editor/Position/PresetListView.swift`
  - Remove the old monitor/preset tree once the new workflow is fully wired.
- Create: `CunningPaperTests/ZonePickerPresentationTests.swift`
  - Cover position summary classification and monitor-specific custom preset filtering.

## Shared Test Command

Use this command after each task that touches compileable app code:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
```

Expected success tail:

```text
** TEST SUCCEEDED **
```

## Task 1: Add Position Presentation Helpers

**Files:**
- Create: `CunningPaper/Editor/Position/ZonePickerPresentation.swift`
- Create: `CunningPaperTests/ZonePickerPresentationTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `CunningPaperTests/ZonePickerPresentationTests.swift` with:

```swift
import XCTest
@testable import CunningPaper

final class ZonePickerPresentationTests: XCTestCase {
    func testSummaryLabelMatchesBuiltInLeftHalf() {
        let label = ZonePickerPresentation.summaryLabel(
            for: DisplayRect(x: 0, y: 0, w: 200, h: 400),
            canvas: CGSize(width: 400, height: 400)
        )

        XCTAssertEqual(label, "Left Half")
    }

    func testSummaryLabelFallsBackToCustom() {
        let label = ZonePickerPresentation.summaryLabel(
            for: DisplayRect(x: 40, y: 40, w: 180, h: 220),
            canvas: CGSize(width: 400, height: 400)
        )

        XCTAssertEqual(label, "Custom")
    }

    func testCustomPresetsOnlyIncludeMatchingMonitor() {
        let monitor = MonitorInfo(name: "Studio", width: 2560, height: 1440, x: 0, y: 0, scaleFactor: 2)
        let presets = [
            ZonePreset(id: "all", label: "All", x: 0, y: 0, w: 1, h: 1, builtIn: false, monitorId: nil, monitorName: nil),
            ZonePreset(id: "studio", label: "Studio Right", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: monitor.id, monitorName: monitor.name),
            ZonePreset(id: "other", label: "Other", x: 0, y: 0, w: 0.5, h: 1, builtIn: false, monitorId: "other-monitor", monitorName: "Other")
        ]

        let filtered = ZonePickerPresentation.customPresets(for: monitor, allPresets: presets)

        XCTAssertEqual(filtered.map(\.id), ["all", "studio"])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' -only-testing:CunningPaperTests/ZonePickerPresentationTests
```

Expected:

```text
Compile error: Cannot find 'ZonePickerPresentation' in scope
```

- [ ] **Step 3: Write the minimal implementation**

Create `CunningPaper/Editor/Position/ZonePickerPresentation.swift` with:

```swift
import CoreGraphics

enum ZonePickerPresentation {
    static let quickPresets: [ZonePreset] = [
        .init(id: "full", label: "Full Screen", x: 0, y: 0, w: 1, h: 1, builtIn: true),
        .init(id: "left", label: "Left Half", x: 0, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "right", label: "Right Half", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "top", label: "Top Half", x: 0, y: 0, w: 1, h: 0.5, builtIn: true),
        .init(id: "bottom", label: "Bottom Half", x: 0, y: 0.5, w: 1, h: 0.5, builtIn: true),
        .init(id: "center", label: "Centered", x: 0.2, y: 0.2, w: 0.6, h: 0.6, builtIn: true),
    ]

    static func customPresets(for monitor: MonitorInfo, allPresets: [ZonePreset]) -> [ZonePreset] {
        allPresets.filter { preset in
            guard !preset.builtIn else { return false }
            if let monitorID = preset.monitorId { return monitorID == monitor.id }
            if let monitorName = preset.monitorName { return monitorName == monitor.name }
            return true
        }
    }

    static func summaryLabel(for rect: DisplayRect?, canvas: CGSize) -> String {
        guard let rect, rect.w > 0, rect.h > 0, canvas.width > 0, canvas.height > 0 else {
            return "No position selected"
        }

        let ratioPreset = ZonePreset(
            id: "current",
            label: "Current",
            x: rect.x / canvas.width,
            y: rect.y / canvas.height,
            w: rect.w / canvas.width,
            h: rect.h / canvas.height,
            builtIn: true
        )

        if let match = quickPresets.first(where: { preset in
            abs(preset.x - ratioPreset.x) < 0.05 &&
            abs(preset.y - ratioPreset.y) < 0.05 &&
            abs(preset.w - ratioPreset.w) < 0.05 &&
            abs(preset.h - ratioPreset.h) < 0.05
        }) {
            return match.label
        }

        return "Custom"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

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
git add CunningPaper/Editor/Position/ZonePickerPresentation.swift CunningPaper.xcodeproj/project.pbxproj CunningPaperTests/ZonePickerPresentationTests.swift
git commit -m "feat: add zone picker presentation helpers"
```

## Task 2: Build Header, Quick Actions, and Saved Positions Surfaces

**Files:**
- Create: `CunningPaper/Editor/Position/PositionHeaderView.swift`
- Create: `CunningPaper/Editor/Position/QuickPositionBar.swift`
- Create: `CunningPaper/Editor/Position/SavedPositionsView.swift`

- [ ] **Step 1: Create the header view**

Create `CunningPaper/Editor/Position/PositionHeaderView.swift` with:

```swift
import SwiftUI

struct PositionHeaderView: View {
    let monitor: MonitorInfo?
    let summary: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Position")
                    .font(.title2.weight(.semibold))

                Text("Choose where the overlay appears on each monitor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 24)

            VStack(alignment: .trailing, spacing: 4) {
                Text(monitor?.name ?? "No display")
                    .font(.headline)
                Text(monitor.map { "\($0.width) × \($0.height) • \($0.orientationLabel)" } ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summary)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.6), in: Capsule())
            }
        }
    }
}
```

- [ ] **Step 2: Create the quick-action bar**

Create `CunningPaper/Editor/Position/QuickPositionBar.swift` with:

```swift
import SwiftUI

struct QuickPositionBar: View {
    let presets: [ZonePreset]
    let activePresetKey: String?
    let onSelect: (ZonePreset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Positions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(presets) { preset in
                    Button(preset.label) {
                        onSelect(preset)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(activePresetKey?.hasSuffix(":\(preset.id)") == true ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
                    )
                }
            }
        }
    }
}
```

- [ ] **Step 3: Create the saved-position section**

Create `CunningPaper/Editor/Position/SavedPositionsView.swift` with:

```swift
import SwiftUI

struct SavedPositionsView: View {
    let presets: [ZonePreset]
    @Binding var draftLabel: String
    let canSave: Bool
    let onSave: () -> Void
    let onSelect: (ZonePreset) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Positions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                TextField("Save current position", text: $draftLabel)
                    .textFieldStyle(.roundedBorder)

                Button("Save") {
                    onSave()
                }
                .disabled(!canSave)
            }

            if presets.isEmpty {
                Text("No saved positions for this monitor yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(presets) { preset in
                        HStack(spacing: 8) {
                            Button(preset.label) {
                                onSelect(preset)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(role: .destructive) {
                                onDelete(preset.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}
```

- [ ] **Step 4: Run the full test suite to verify the new views compile**

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
git add CunningPaper/Editor/Position/PositionHeaderView.swift CunningPaper/Editor/Position/QuickPositionBar.swift CunningPaper/Editor/Position/SavedPositionsView.swift CunningPaper.xcodeproj/project.pbxproj
git commit -m "feat: add zone picker workflow views"
```

## Task 3: Refactor ZonePickerView Around the Canvas Workflow

**Files:**
- Modify: `CunningPaper/Editor/Position/ZonePickerView.swift`

- [ ] **Step 1: Replace split-view layout with the new vertical workflow**

Update `CunningPaper/Editor/Position/ZonePickerView.swift` so the `body` becomes:

```swift
var body: some View {
    VStack(alignment: .leading, spacing: 18) {
        PositionHeaderView(
            monitor: state.activeMonitor,
            summary: currentSummary
        )

        if let monitor = state.activeMonitor {
            let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)

            VStack(alignment: .leading, spacing: 16) {
                GridCanvasView(
                    monitor: monitor,
                    canvas: canvas,
                    selection: state.activeSelection,
                    onSelectionChange: { rect in
                        state.activeSelection = rect
                        state.activePresetKey = nil
                    },
                    onSelectionCommit: { rect in
                        state.activeSelection = rect
                        state.activePresetKey = nil
                        applyAndSave(rect: rect, monitor: monitor, canvas: canvas)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .center)

                QuickPositionBar(
                    presets: ZonePickerPresentation.quickPresets,
                    activePresetKey: state.activePresetKey,
                    onSelect: { preset in
                        handleQuickPresetSelect(preset, monitorIndex: state.activeMonitorIndex)
                    }
                )

                SavedPositionsView(
                    presets: activeCustomPresets,
                    draftLabel: $state.newPresetLabel,
                    canSave: state.activeSelection != nil,
                    onSave: { saveCurrentSelection() },
                    onSelect: { preset in
                        handlePresetSelect(monitorIndex: state.activeMonitorIndex, preset: preset)
                    },
                    onDelete: handlePresetDelete
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            ContentUnavailableView("No display found", systemImage: "display")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    .padding(20)
    .task {
        ensurePrefsExists()
        loadMonitors()
    }
}
```

- [ ] **Step 2: Extend state and derived helpers to support the new flow**

Add these properties to `ZonePickerState` and `ZonePickerView`:

```swift
var newPresetLabel = ""
```

```swift
private var activeCustomPresets: [ZonePreset] {
    guard let monitor = state.activeMonitor else { return [] }
    return ZonePickerPresentation.customPresets(for: monitor, allPresets: prefs?.customPresets ?? [])
}

private var currentSummary: String {
    guard let monitor = state.activeMonitor else { return "No position selected" }
    let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
    return ZonePickerPresentation.summaryLabel(
        for: state.activeSelection,
        canvas: CGSize(width: canvas.width, height: canvas.height)
    )
}
```

- [ ] **Step 3: Add quick-preset and save-current helpers**

Add these methods to `ZonePickerView.swift`:

```swift
private func handleQuickPresetSelect(_ preset: ZonePreset, monitorIndex: Int) {
    handlePresetSelect(monitorIndex: monitorIndex, preset: preset)
}

private func saveCurrentSelection() {
    let trimmed = state.newPresetLabel.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    handlePresetAdd(monitorIndex: state.activeMonitorIndex, label: trimmed)
    state.newPresetLabel = ""
}
```

- [ ] **Step 4: Run tests to verify the refactor still builds**

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
git add CunningPaper/Editor/Position/ZonePickerView.swift
git commit -m "feat: refactor zone picker around canvas workflow"
```

## Task 4: Strengthen Canvas Feedback and Remove the Old Preset Browser

**Files:**
- Modify: `CunningPaper/Editor/Position/GridCanvasView.swift`
- Delete: `CunningPaper/Editor/Position/PresetListView.swift`

- [ ] **Step 1: Improve selection readability in the canvas**

Update the canvas drawing in `CunningPaper/Editor/Position/GridCanvasView.swift`:

```swift
context.fill(
    Path(roundedRect: rect, cornerRadius: 2),
    with: .color(isSelected ? Color.accentColor.opacity(0.9) : Color(nsColor: .quaternaryLabelColor))
)

if isSelected {
    context.stroke(
        Path(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 2),
        with: .color(.white.opacity(0.9)),
        lineWidth: 1
    )
}
```

Then add a stronger frame/background treatment:

```swift
.background(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color(nsColor: .windowBackgroundColor))
)
.overlay(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
)
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
```

- [ ] **Step 2: Remove the obsolete split-view preset browser**

Delete `CunningPaper/Editor/Position/PresetListView.swift`.

- [ ] **Step 3: Run the full test suite and a build-only sanity check**

Run:

```bash
xcodebuild test -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS'
xcodebuild -project CunningPaper.xcodeproj -scheme CunningPaper -destination 'platform=macOS' build
```

Expected:

```text
** TEST SUCCEEDED **
** BUILD SUCCEEDED **
```

- [ ] **Step 4: Commit**

```bash
git add CunningPaper/Editor/Position/GridCanvasView.swift CunningPaper.xcodeproj/project.pbxproj
git rm CunningPaper/Editor/Position/PresetListView.swift
git commit -m "feat: finalize zone picker redesign"
```

## Self-Review

- Spec coverage: The plan covers the agreed redesign goals of canvas-first placement, current-state communication, quick built-in actions, and secondary saved-position management. It intentionally does not expand persistence scope, add drag handles, or introduce multi-monitor batch editing.
- Placeholder scan: No `TODO`, `TBD`, or “implement later” gaps remain. Each task lists exact files, commands, and concrete code to add or modify.
- Type consistency: The plan introduces `ZonePickerPresentation`, `PositionHeaderView`, `QuickPositionBar`, and `SavedPositionsView` consistently across tasks. `ZonePickerState.newPresetLabel`, `currentSummary`, and `activeCustomPresets` are defined before later tasks depend on them.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-02-zone-picker-redesign.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
