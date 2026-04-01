import SwiftData
import SwiftUI

struct CardListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CardModel.order) private var cards: [CardModel]
    @Binding var selectedCardID: UUID?

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

                        Text("\(card.paragraphCount) paragraphs")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .tag(card.id)
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
    }

    private func addBlankCard() {
        let nextOrder = (cards.map(\.order).max() ?? -1) + 1
        let card = CardModel(body: "", order: nextOrder)
        context.insert(card)
        guard saveContext() else {
            context.delete(card)
            return
        }
        selectedCardID = card.id
    }

    private func moveCards(from source: IndexSet, to destination: Int) {
        var reordered = cards
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, card) in reordered.enumerated() {
            card.order = Double(index)
        }
        _ = saveContext()
    }

    private func saveContext() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            assertionFailure("Failed to save card list changes: \(error)")
            return false
        }
    }
}
