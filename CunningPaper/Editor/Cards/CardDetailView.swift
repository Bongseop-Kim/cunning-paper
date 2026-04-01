import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.undoManager) private var undoManager
    @Query private var cards: [CardModel]

    let cardID: UUID
    let onDelete: () -> Void

    private var card: CardModel? {
        cards.first(where: { $0.id == cardID })
    }

    var body: some View {
        Group {
            if let card {
                VStack(spacing: 0) {
                    TextField(
                        "Title",
                        text: Binding(
                            get: { card.title },
                            set: {
                                card.title = $0
                                card.updatedAt = Date()
                                try? context.save()
                            }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 12)

                    Divider()

                    TextEditor(
                        text: Binding(
                            get: { card.body },
                            set: {
                                card.body = $0
                                card.updatedAt = Date()
                                try? context.save()
                            }
                        )
                    )
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    Divider()

                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            context.delete(card)
                            try? context.save()
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.plain)
                        .padding(12)
                    }
                }
                .onAppear {
                    context.undoManager = undoManager
                }
            } else {
                ContentUnavailableView("Card not found", systemImage: "doc")
            }
        }
    }
}
