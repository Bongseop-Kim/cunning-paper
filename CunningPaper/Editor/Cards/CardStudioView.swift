import SwiftData
import SwiftUI

struct CardStudioView: View {
    @Query(sort: \CardModel.order) private var cards: [CardModel]
    @Binding var selectedCardID: UUID?
    @State private var activeParagraphIndex: Int?

    private var selectedCard: CardModel? {
        cards.first(where: { $0.id == selectedCardID })
    }

    private func selectCard(_ id: UUID) {
        activeParagraphIndex = 0
        selectedCardID = id
    }

    private func clearInvalidSelectionIfNeeded() {
        guard let selectedCardID, !cards.contains(where: { $0.id == selectedCardID }) else { return }
        resetSelection()
    }

    @ViewBuilder
    private var detailPane: some View {
        if let selectedCard {
            selectedCardPane(for: selectedCard)
        } else {
            emptyStatePane
        }
    }

    private func selectedCardPane(for selectedCard: CardModel) -> some View {
        VStack(spacing: 0) {
            previewPane(for: selectedCard)
            detailEditor(for: selectedCard)
        }
    }

    private func previewPane(for selectedCard: CardModel) -> some View {
        CardPreviewPane(
            paragraphs: selectedCard.paragraphs,
            activeParagraphIndex: activeParagraphIndex
        )
        .frame(height: 208)
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var emptyStatePane: some View {
        CardEmptyStateView(onAddBlank: selectCard)
    }

    private func resetSelection() {
        activeParagraphIndex = nil
        selectedCardID = nil
    }

    private func updateActiveParagraph(_ index: Int?) {
        activeParagraphIndex = index
    }

    private func detailEditor(for selectedCard: CardModel) -> some View {
        CardDetailView(
            card: selectedCard,
            onActiveParagraphChange: updateActiveParagraph,
            onDelete: resetSelection
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            CardListView(selectedCardID: $selectedCardID)
                .frame(width: 232)

            Divider()

            detailPane
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.16), value: selectedCardID)
        }
        .onAppear(perform: clearInvalidSelectionIfNeeded)
        .onChange(of: selectedCardID) { _, selectedCardID in
            guard selectedCardID != nil else { return }
            activeParagraphIndex = 0
            clearInvalidSelectionIfNeeded()
        }
        .onChange(of: cards.map(\.id)) { _, cardIDs in
            guard let selectedCardID, !cardIDs.contains(selectedCardID) else { return }
            resetSelection()
        }
    }
}
