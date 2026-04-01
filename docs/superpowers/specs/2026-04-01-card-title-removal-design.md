# CunningPaper Card Title Removal

Date: 2026-04-01
Status: Proposed
Scope: Card data model, editor card surfaces, overlay card rendering

## Context

The current card flow still treats `title` as a first-class field:

- the editor list shows a title-derived label
- the detail pane edits `title` separately from `body`
- the preview and overlay both accept and render title text
- the overlay includes a search panel that also depends on title-based display

This no longer matches the intended product behavior. Cards should be body-first. Any title-like affordance in the editor should be a UI convenience derived from the body, not stored data.

## Goal

Remove stored card titles from the product while preserving fast scanning in the editor list.

The resulting experience should:

- store only card body content plus ordering and timestamps
- remove title editing from the editor
- remove title rendering from preview and overlay
- remove overlay search entirely, including its trigger path
- keep the card list readable by deriving lightweight summary text from the body

## Chosen Direction

Selected direction: remove `title` from the model and keep a list-only derived summary.

Why this direction:

- It matches the requirement to remove titles completely rather than merely hide them.
- It reduces duplicated card concepts by making `body` the only authored content.
- It keeps the editor usable by deriving list labels from existing text instead of reintroducing a second field.

## Data Model

`CardModel` should no longer store `title`.

The model remains responsible for:

- `id`
- `body`
- `order`
- `createdAt`
- `updatedAt`
- paragraph-derived helpers used by the UI

Existing stored cards must continue to preserve:

- body text
- ordering
- creation and update timestamps

Legacy title values are intentionally discarded in the new model.

## UI Rules

## Card list

`CardListView` should keep a two-line summary plus metadata.

Display rules:

- line 1: first word from the card body, styled like a lightweight title
- line 2: first line from the card body, shortened to fit one line
- meta: paragraph count

Empty-body fallback:

- line 1: `Empty`
- line 2: `Empty card`

This summary is presentational only. It does not create a new persistent title concept.

## Card detail

`CardDetailView` should remove the title field completely.

The detail pane should contain:

- paragraph count header
- body editor
- existing delete affordance

The user edits only body text.

## Preview and overlay

Preview and overlay render only paragraphs.

`CardPreviewPane`, `CardDisplayView`, and `OverlayView` should stop accepting or passing title text.

The visual structure remains the same except that any title row above the paragraph stack is removed.

## Overlay search removal

Overlay search is removed entirely.

This includes:

- the search panel view
- overlay state used only for search
- search hotkey handling
- any title-based search result presentation

After this change, overlay navigation consists only of:

- previous card
- next card
- jump panel
- previous paragraph
- next paragraph

## Component Changes

## `CardModel`

- remove `title`
- remove title-derived helpers such as `displayTitle`
- keep or add body-derived helpers needed for list summary text

## `CardListView`

- stop reading `displayTitle`
- derive first-word and first-line summary from body helpers
- keep paragraph count metadata

## `CardDetailView`

- remove title `TextField`
- stop creating bindings for title mutations
- continue saving body edits and delete actions

## `CardStudioView`

- stop passing title into preview

## `CardPreviewPane`

- remove title input
- render preview from paragraph data only

## `CardDisplayView`

- remove title properties and title rendering branch
- keep paragraph rendering, highlighting, and fade behavior

## `OverlayView`

- remove search-related panel state and handlers
- pass paragraph-only data into `CardDisplayView`

## `SearchPanelView`

- remove the file if no longer referenced

## Migration and Compatibility

The persistence layer must be updated so the app can load existing cards after removing `title` from the model.

Required compatibility outcome:

- an existing user can open the app without losing cards
- cards keep their existing body text and ordering
- removed title data does not block loading or editing

If a schema migration is already present for cards, extend it in the same pattern rather than creating a separate persistence strategy.

## Error Handling

No new user-facing error flows are needed.

Existing save behavior should remain:

- body edits still save through the current persistence path
- failed saves still restore prior values where that behavior already exists
- card creation and deletion still preserve current rollback behavior

## Testing and Verification

Manual verification is sufficient for this change unless the repo already has focused tests for these surfaces.

Required checks:

1. Create a new card and confirm only body text is editable.
2. Confirm the card list shows first-word summary, first-line summary, and paragraph count.
3. Confirm empty cards show `Empty` and `Empty card`.
4. Confirm preview no longer shows title text.
5. Confirm overlay no longer shows title text.
6. Confirm overlay search UI and search hotkey path are gone.
7. Confirm existing stored cards still load with their body content and ordering intact.

## Risks

- Removing `title` from SwiftData can break loading if migration is incomplete.
- Deriving the first-word summary naively can produce awkward results for punctuation-only or whitespace-heavy content.
- Removing overlay search requires checking for leftover hotkey references so the app does not expose dead commands.

## Out of Scope

- redesigning the list layout beyond the agreed summary change
- replacing overlay search with another navigation feature
- changing paragraph parsing semantics beyond what is needed for summary text
