import SwiftData
import SwiftUI

struct CardDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.undoManager) private var undoManager

    let card: CardModel
    let onActiveParagraphChange: (Int?) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(card.paragraphCountLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 10)

            TextField(
                "Card title",
                text: textBinding(for: \.title)
            )
            .textFieldStyle(.plain)
            .font(.system(size: 28, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 18)

            CardBodyTextView(
                text: textBinding(for: \.body),
                onActiveParagraphChange: onActiveParagraphChange
            )
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .onAppear {
            context.undoManager = undoManager
        }
        .onDisappear {
            context.undoManager = nil
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        deleteCard()
                    } label: {
                        Text("Delete Card")
                    }
                } label: {
                    Text("More")
                }
            }
        }
    }

    private func textBinding(for keyPath: ReferenceWritableKeyPath<CardModel, String>) -> Binding<String> {
        Binding(
            get: { card[keyPath: keyPath] },
            set: { newValue in
                let previousValue = card[keyPath: keyPath]
                let previousUpdatedAt = card.updatedAt
                card[keyPath: keyPath] = newValue
                card.updatedAt = Date()
                saveCardMutation {
                    card[keyPath: keyPath] = previousValue
                    card.updatedAt = previousUpdatedAt
                }
            }
        )
    }

    private func saveCardMutation(restore: () -> Void) {
        do {
            try context.save()
        } catch {
            restore()
            assertionFailure("Failed to save card changes: \(error)")
        }
    }

    private func deleteCard() {
        context.delete(card)

        do {
            try context.save()
            onDelete()
        } catch {
            context.insert(card)
            assertionFailure("Failed to delete card: \(error)")
        }
    }
}
