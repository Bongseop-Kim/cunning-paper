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
            if prefs?.readingMode == .manual {
                engine.advanceParagraph()
            }
        case .prevLine:
            if prefs?.readingMode == .manual {
                engine.retractParagraph()
            }
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
