import AppKit
import OSLog
import SwiftData
import SwiftUI

struct CardListView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "CunningPaper",
        category: "CardListView"
    )

    enum MutationError: LocalizedError {
        case cardNotFound(UUID)

        var errorDescription: String? {
            switch self {
            case .cardNotFound(let id):
                return "Card not found for deletion: \(id.uuidString)"
            }
        }
    }

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
        switch Self.persist(context) {
        case .success:
            selectedCardID = card.id
        case .failure(let error):
            context.delete(card)
            Self.handleMutationSaveFailure(
                error,
                fallbackMessage: "The card could not be created.",
                rollback: {},
                presentError: presentSaveError,
                playFailureSound: { NSSound.beep() }
            )
        }
    }

    private func deleteCard(_ card: CardModel) {
        let previousSelection = selectedCardID
        let nextSelection = nextSelectionAfterDeletingCard(withID: card.id)
        switch Self.performIsolatedMutation(in: context.container, mutate: { mutationContext in
            try Self.deleteCard(withID: card.id, in: mutationContext)
        }) {
        case .success:
            selectedCardID = nextSelection
        case .failure(let error):
            Self.handleMutationSaveFailure(
                error,
                fallbackMessage: "The card could not be deleted.",
                rollback: {
                    selectedCardID = previousSelection
                },
                presentError: presentSaveError,
                playFailureSound: { NSSound.beep() }
            )
        }
    }

    static func deleteCard(withID cardID: UUID, in mutationContext: ModelContext) throws {
        var descriptor = FetchDescriptor<CardModel>(
            predicate: #Predicate<CardModel> { $0.id == cardID }
        )
        descriptor.fetchLimit = 1
        guard let cardToDelete = try mutationContext.fetch(descriptor).first else {
            throw MutationError.cardNotFound(cardID)
        }
        mutationContext.delete(cardToDelete)
    }

    private func moveCards(from source: IndexSet, to destination: Int) {
        var reordered = cards
        reordered.move(fromOffsets: source, toOffset: destination)
        let reorderedCardIDs = reordered.map(\.id)
        switch Self.performIsolatedMutation(in: context.container, mutate: { mutationContext in
            let cards = try mutationContext.fetch(FetchDescriptor<CardModel>())
            let cardsByID = Dictionary(uniqueKeysWithValues: cards.map { ($0.id, $0) })
            for (index, id) in reorderedCardIDs.enumerated() {
                cardsByID[id]?.order = Double(index)
            }
        }) {
        case .success:
            break
        case .failure(let error):
            Self.handleMutationSaveFailure(
                error,
                fallbackMessage: "The cards could not be reordered.",
                rollback: {},
                presentError: presentSaveError,
                playFailureSound: { NSSound.beep() }
            )
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
        let details = Self.logSafeSaveErrorDetails(for: error)
        let context = Self.logContext(for: error)
        Self.logger.error(
            "Failed to save card list changes: domain=\(details.domain, privacy: .public) code=\(details.code, privacy: .public) description=\(details.description, privacy: .private) context=\(context, privacy: .public)"
        )
        errorMessage = Self.presentableSaveErrorMessage(for: error, fallbackMessage: fallbackMessage)
    }

    static func handleMutationSaveFailure(
        _ error: Error,
        fallbackMessage: String,
        rollback: () -> Void,
        presentError: (Error, String) -> Void,
        playFailureSound: () -> Void
    ) {
        rollback()
        presentError(error, fallbackMessage)
        playFailureSound()
    }

    static func performIsolatedMutation(
        in container: ModelContainer,
        mutate: (ModelContext) throws -> Void,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) -> Result<Void, Error> {
        let mutationContext = ModelContext(container)
        do {
            try mutate(mutationContext)
            return persist(mutationContext, save: save)
        } catch {
            mutationContext.rollback()
            return .failure(error)
        }
    }

    static func persist(
        _ context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) -> Result<Void, Error> {
        do {
            try save(context)
            return .success(())
        } catch {
            NSLog("Failed to save card list changes: %@", error.localizedDescription)
            return .failure(error)
        }
    }

    static func presentableSaveErrorMessage(for error: Error, fallbackMessage: String) -> String {
        fallbackMessage
    }

    static func logSafeSaveErrorDetails(for error: Error) -> (domain: String, code: Int, description: String) {
        let nsError = error as NSError
        return (nsError.domain, nsError.code, error.localizedDescription)
    }

    static func logContext(for error: Error) -> String {
        guard case MutationError.cardNotFound(let cardID) = error else {
            return "none"
        }
        return "cardID=\(cardID.uuidString)"
    }
}
