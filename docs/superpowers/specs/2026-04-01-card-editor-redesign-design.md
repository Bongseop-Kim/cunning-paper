# CunningPaper Card Editor Redesign

Date: 2026-04-01
Status: Proposed
Scope: Card editor only

## Context

CunningPaper already has a clear product core:

- overlay reading experience
- card authoring workflow
- position and preset control

The current card editor works functionally, but it still reads as a generic macOS utility. The strongest product idea in this app is not "editing text" but "shaping text for live reading." The editor should reflect that purpose directly.

This redesign focuses on making the card editor feel like a reading studio rather than a default form split view.

## Goal

Reframe the card editor as a brand-forward writing and preview surface that:

- shows the reading result while editing
- improves scanning and selection speed in the card list
- reduces generic system-form feeling
- keeps the UI calm, dense, and practical

## Chosen Direction

Selected direction: Reading studio

Why this direction:

- It best matches the product identity.
- It ties editing to the live overlay outcome.
- It adds product character without harming utility.
- It is safer than a fully experimental canvas-style editor.

## Visual Thesis

Quiet, editorial, and deliberate. The editor should feel closer to a reading console than a note app: restrained chrome, strong typography, dark preview surface, and a single accent color used only for state.

## Content Plan

- left pane: scan and select cards quickly
- right top: see how the current card reads
- right bottom: edit title and body with minimal friction

Each region gets one job only.

## Interaction Thesis

- selecting a card should update preview and editor with a short, restrained transition
- the current selection should be obvious in the list without loud visual noise
- creating a new card should immediately move focus into writing

## Layout

## High-level structure

- left pane: `CardListPane`
- right pane top: `CardPreviewPane`
- right pane bottom: `CardFormPane`

## Proposed proportions

- left pane width: 220-240px
- right pane top preview height: 180-220px
- right pane bottom form: remaining height

## Behavior

- if a card is selected, show preview + form
- if no card is selected, show a refined empty state in the right pane

## Design Rules

- use whitespace and type scale before adding borders
- use one accent color only for selection and emphasis
- keep the experience cardless by default
- keep surfaces flat and intentional rather than stacked with boxes
- treat the preview as the visual anchor of the editor

## Component Plan

## 1. CardStudioView

Responsibility:

- own the full card editor composition
- place list on the left and the studio surface on the right
- decide whether to show preview + form or empty state

Notes:

- this becomes the card-tab root view
- `EditorView` should stop assembling the card layout directly

## 2. CardListView

Responsibility:

- support fast scanning
- make selection unmistakable
- keep create action available without dominating the pane

Changes:

- list rows become `title / first line / meta`
- meta should show one compact signal such as paragraph count or last updated time
- selected row should use a left accent bar, stronger title weight, and a subtle tinted background
- the bottom create action should feel like a tool action, not a lonely footer button

## 3. CardPreviewPane

Responsibility:

- show the current card in a compact overlay-like preview
- remind the user what they are writing toward

Changes:

- use a dark charcoal surface
- reuse or align with overlay typography rules
- preserve current-paragraph emphasis
- keep empty or untitled cards visually stable

## 4. CardDetailView

Responsibility:

- provide focused writing inputs
- surface light metadata without visual clutter

Changes:

- add a thin meta header above the title field
- enlarge the title field presence
- give the body more comfortable inset and line rhythm
- reduce reliance on `Divider`
- move destructive action into a lower-emphasis control, ideally menu or toolbar placement

## 5. CardEmptyStateView

Responsibility:

- get a first card created quickly
- make sample content secondary

Changes:

- primary CTA becomes `Create First Card`
- `Add Samples` becomes a secondary action
- copy becomes shorter and product-facing
- visual tone should match the studio surface

## Detailed UX Notes

## Card list

- every row should communicate title first
- supporting text must be short enough to scan in one glance
- avoid heavy background fills on every row
- the selected row should feel anchored, not highlighted like a generic sidebar item

## Preview pane

- preview must feel like the product hero inside the editor
- title should be present but secondary to the reading body
- paragraph emphasis should be noticeable but calm
- the preview should not look like a fake screenshot or a separate app

## Form pane

- title entry should feel intentional and editorial
- body editing should prioritize legibility over decoration
- destructive actions should not sit in the main reading flow

## Empty state

- primary message: start writing
- secondary message: samples exist if needed
- avoid over-explaining the product here

## Copy Direction

Use product copy, not design commentary.

Examples:

- `Create First Card`
- `Write the next section`
- `Preview updates as you edit`

Avoid:

- abstract productivity promises
- setup-heavy phrasing
- technical filler such as "seed the editor"

## Motion

Motion should stay restrained and short.

Recommended:

- card selection: short fade between preview states
- new card creation: immediate focus transition into the title field
- selection emphasis: subtle state change, not animated spectacle

Avoid:

- large sliding panes
- decorative bounce
- excessive opacity transitions across the whole screen

## Implementation Plan

## File changes

`CunningPaper/Editor/EditorView.swift`

- replace direct card-tab assembly with `CardStudioView`

`CunningPaper/Editor/Cards/CardStudioView.swift`

- new root composition for the card editing experience

`CunningPaper/Editor/Cards/CardPreviewPane.swift`

- new compact reading preview

`CunningPaper/Editor/Cards/CardListView.swift`

- redesign row information and selection treatment

`CunningPaper/Editor/Cards/CardDetailView.swift`

- restructure header, body area, and destructive actions

`CunningPaper/Editor/Cards/CardEmptyStateView.swift`

- rebalance CTA hierarchy and copy

## Execution order

1. Add `CardStudioView`
2. Add `CardPreviewPane`
3. Connect `EditorView`
4. Redesign `CardListView`
5. Redesign `CardDetailView`
6. Refine `CardEmptyStateView`

## Risks

- Over-styling the list could hurt native readability.
- A preview that looks too separate from the form could fragment the workflow.
- Keeping too much system default styling in the form would weaken the redesign.
- Moving destructive actions must preserve clarity and safety.

## Out of Scope

- preferences redesign
- overlay redesign
- tab bar redesign
- position and preset redesign
- model changes unrelated to card editor presentation

## Acceptance Criteria

- the card editor feels like a reading-focused studio instead of a generic split form
- users can scan the card list faster than before
- the current card's reading outcome is visible while editing
- the primary create path is clearer in the empty state
- destructive actions no longer dominate the bottom edge of the editor

## Self-Review

Checked for:

- placeholder sections: none
- contradictions: none found
- scope drift: limited to card editor
- ambiguity: implementation order and component responsibilities are explicit enough to begin planning
