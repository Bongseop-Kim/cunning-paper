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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title.isEmpty ? "Untitled" : card.title)
                            .font(.body.weight(.medium))
                        Text(card.paragraphs.first ?? "Empty card")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .tag(card.id)
                }
                .onMove(perform: moveCards)
            }
            .listStyle(.sidebar)

            Divider()

            Button {
                addBlankCard()
            } label: {
                Label("New Card", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private func addBlankCard() {
        let nextOrder = (cards.map(\.order).max() ?? -1) + 1
        let card = CardModel(title: "", body: "", order: nextOrder)
        context.insert(card)
        try? context.save()
        selectedCardID = card.id
    }

    private func moveCards(from source: IndexSet, to destination: Int) {
        var reordered = cards
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, card) in reordered.enumerated() {
            card.order = Double(index)
        }
        try? context.save()
    }
}
