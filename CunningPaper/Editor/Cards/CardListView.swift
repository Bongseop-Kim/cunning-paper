import AppKit
import SwiftData
import SwiftUI

struct CardListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CardModel.order) private var cards: [CardModel]
    @Binding var selectedCardID: UUID?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedCardID) {
                ForEach(cards) { card in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(card.listHeadline)
                            .font(.body.weight(.medium))
                            .lineLimit(1)

                        Text(card.listSubheadline)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text("^[\(card.paragraphCount) paragraph](inflect: true)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .tag(card.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteCard(card)
                        } label: {
                            Label("Delete Card", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: moveCards)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color.clear)

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
        }
        .alert("Couldn't Save Changes", isPresented: errorPresented) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "The change could not be saved.")
        }
    }

    private func addBlankCard() {
        let nextOrder = (cards.map(\.order).max() ?? -1) + 1
        let card = CardModel(body: "", order: nextOrder)
        context.insert(card)
        guard case .success = saveContext() else {
            context.delete(card)
            return
        }
        selectedCardID = card.id
    }

    private func deleteCard(_ card: CardModel) {
        let previousSelection = selectedCardID
        let nextSelection = nextSelectionAfterDeletingCard(withID: card.id)
        context.delete(card)
        switch saveContext() {
        case .success:
            selectedCardID = nextSelection
        case .failure(let error):
            context.rollback()
            selectedCardID = previousSelection
            presentSaveError(error, fallbackMessage: "The card could not be deleted.")
            NSSound.beep()
        }
    }

    private func moveCards(from source: IndexSet, to destination: Int) {
        var reordered = cards
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, card) in reordered.enumerated() {
            card.order = Double(index)
        }
        switch saveContext() {
        case .success:
            break
        case .failure(let error):
            context.rollback()
            presentSaveError(error, fallbackMessage: "The cards could not be reordered.")
            NSSound.beep()
        }
    }

    private func nextSelectionAfterDeletingCard(withID cardID: UUID) -> UUID? {
        guard selectedCardID == cardID,
              let index = cards.firstIndex(where: { $0.id == cardID })
        else {
            return selectedCardID
        }

        if index + 1 < cards.count {
            return cards[index + 1].id
        }
        if index - 1 >= 0 {
            return cards[index - 1].id
        }
        return nil
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func presentSaveError(_ error: Error, fallbackMessage: String) {
        let description = error.localizedDescription
        errorMessage = description.isEmpty ? fallbackMessage : description
    }

    private func saveContext() -> Result<Void, Error> {
        do {
            try context.save()
            return .success(())
        } catch {
            NSLog("Failed to save card list changes: %@", error.localizedDescription)
            assertionFailure("Failed to save card list changes: \(error)")
            return .failure(error)
        }
    }
}
