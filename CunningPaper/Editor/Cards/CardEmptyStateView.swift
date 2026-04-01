import SwiftData
import SwiftUI

struct CardEmptyStateView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CardModel.order) private var cards: [CardModel]

    let onAddBlank: (UUID) -> Void

    private let sampleCards: [(String, String)] = [
        ("Introduction", "I build products by reducing ambiguity.\nI care about the edges, not just the happy path."),
        ("Recent Work", "The last major project focused on a dense operations UI.\nI restructured the flow around decisions rather than raw data."),
        ("Why This Role", "I prefer teams that value speed and taste together.\nShipping is better when the structure is clear from the start."),
    ]

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("Select a card or create one")
                .font(.headline)
            Text("Start with a blank card or seed the editor with sample content.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            HStack(spacing: 12) {
                Button("Add Samples", action: addSamples)
                    .buttonStyle(.borderedProminent)
                Button("Blank Card", action: addBlankCard)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func addBlankCard() {
        let nextOrder = (cards.map(\.order).max() ?? -1) + 1
        let card = CardModel(title: "", body: "", order: nextOrder)
        context.insert(card)
        try? context.save()
        onAddBlank(card.id)
    }

    private func addSamples() {
        let startOrder = (cards.map(\.order).max() ?? -1) + 1
        var created: [CardModel] = []
        for (index, sample) in sampleCards.enumerated() {
            let card = CardModel(title: sample.0, body: sample.1, order: startOrder + Double(index))
            context.insert(card)
            created.append(card)
        }
        try? context.save()
        if let first = created.first {
            onAddBlank(first.id)
        }
    }
}
