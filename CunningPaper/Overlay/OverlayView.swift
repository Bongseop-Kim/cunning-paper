import AppKit
import SwiftData
import SwiftUI

enum ActivePanel: Equatable {
    case none
    case jump
    case search
}

struct OverlayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CardModel.order) private var cards: [CardModel]
    @Query private var prefsArray: [PrefsModel]
    @State private var currentIndex = 0
    @State private var activeParagraphIndex = 0
    @State private var activePanel: ActivePanel = .none

    private var prefs: PrefsModel? { prefsArray.first }

    private var currentCard: CardModel? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    init() {}

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(prefs?.opacity ?? 0.85))

            CardDisplayView(
                title: currentCard?.title ?? "",
                paragraphs: currentCard?.paragraphs ?? ["No cards yet"],
                activeIndex: activeParagraphIndex,
                fontSize: prefs?.fontSize ?? 24,
                highlightCurrentParagraph: prefs?.highlightCurrentParagraph ?? true
            )

            if activePanel == .jump {
                JumpPanelView(
                    totalCards: cards.count,
                    onJump: { index in
                        currentIndex = index
                        activeParagraphIndex = 0
                        closePanel()
                    },
                    onClose: closePanel
                )
            }

            if activePanel == .search {
                SearchPanelView(
                    cards: cards,
                    onSelect: { card in
                        if let index = cards.firstIndex(where: { $0.id == card.id }) {
                            currentIndex = index
                            activeParagraphIndex = 0
                        }
                        closePanel()
                    },
                    onClose: closePanel
                )
            }
        }
        .padding(6)
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
            if currentIndex < cards.count - 1 { currentIndex += 1 }
        case .prev:
            if currentIndex > 0 { currentIndex -= 1 }
        case .jump:
            activePanel = .jump
        case .search:
            activePanel = .search
        case .nextLine:
            let maxIndex = max((currentCard?.paragraphs.count ?? 1) - 1, 0)
            if activeParagraphIndex < maxIndex { activeParagraphIndex += 1 }
        case .prevLine:
            if activeParagraphIndex > 0 { activeParagraphIndex -= 1 }
        case .toggle:
            break
        }
    }

    private func closePanel() {
        activePanel = .none
    }

    private func updateClickThrough(for panel: ActivePanel) {
        guard let overlayWindow = NSApp.windows.first(where: { $0 is OverlayPanel }) else { return }
        overlayWindow.ignoresMouseEvents = (panel == .none)
    }
}
