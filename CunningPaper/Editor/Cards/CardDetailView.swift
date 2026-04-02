import OSLog
import SwiftData
import SwiftUI

struct CardDetailView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "CunningPaper",
        category: "CardDetailView"
    )

    @Environment(\.modelContext) private var context
    @Environment(\.undoManager) private var undoManager
    @State private var saveErrorMessage: String?

    let card: CardModel
    let onActiveParagraphChange: (Int?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(card.paragraphCountLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 12)

            CardBodyTextView(
                text: textBinding(for: \.body),
                documentID: card.id,
                onActiveParagraphChange: onActiveParagraphChange
            )
            .id(card.id)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onAppear {
            context.undoManager = undoManager
        }
        .onDisappear {
            context.undoManager = nil
        }
        .alert("Couldn't Save Changes", isPresented: saveErrorPresented) {
            Button("OK") {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "The card change could not be saved.")
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
            presentSaveError(error, fallbackMessage: "The card change could not be saved.")
            assertionFailure("Failed to save card changes: \(error)")
        }
    }

    private var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    saveErrorMessage = nil
                }
            }
        )
    }

    private func presentSaveError(_ error: Error, fallbackMessage: String) {
        let description = error.localizedDescription
        Self.logger.error("Failed to save card changes: \(String(describing: error), privacy: .public)")
        saveErrorMessage = description.isEmpty ? fallbackMessage : description
    }
}
