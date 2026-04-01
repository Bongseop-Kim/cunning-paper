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
        VStack(alignment: .center, spacing: 18) {
            Text("Create your first card")
                .font(.title3.weight(.semibold))

            Text("Create a card and see its reading preview as you write.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)

            VStack(spacing: 10) {
                Button("Create First Card", action: addBlankCard)
                    .buttonStyle(.borderedProminent)

                Button("Add Samples", action: addSamples)
                    .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private func addBlankCard() {
        let nextOrder = (cards.map(\.order).max() ?? -1) + 1
        let card = CardModel(title: "", body: "", order: nextOrder)
        context.insert(card)
        guard saveContext() else {
            context.delete(card)
            return
        }
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
        guard saveContext() else {
            for card in created {
                context.delete(card)
            }
            return
        }
        if let first = created.first {
            onAddBlank(first.id)
        }
    }

    private func saveContext() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            assertionFailure("Failed to save empty-state card changes: \(error)")
            return false
        }
    }
}
