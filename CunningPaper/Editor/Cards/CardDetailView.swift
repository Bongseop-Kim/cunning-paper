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
    @State private var previousUndoManager: UndoManager?

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
            previousUndoManager = Self.installUndoManager(undoManager, in: context)
        }
        .onChange(of: card.id) { _, _ in
            Self.prepareForCardChange(
                saveErrorMessage: &saveErrorMessage,
                using: onActiveParagraphChange
            )
        }
        .onDisappear {
            Self.resetActiveParagraph(using: onActiveParagraphChange)
            Self.restoreUndoManager(previousUndoManager, in: context)
            previousUndoManager = nil
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
                Self.applyTextChange(newValue, for: keyPath, on: card, save: saveCardMutation)
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
        let details = Self.logSafeSaveErrorDetails(for: error)
        Self.logger.error(
            "Failed to save card changes: domain=\(details.domain, privacy: .public) code=\(details.code, privacy: .public) description=\(details.description, privacy: .private)"
        )
        let description = details.description
        saveErrorMessage = description.isEmpty ? fallbackMessage : description
    }

    static func applyTextChange(
        _ newValue: String,
        for keyPath: ReferenceWritableKeyPath<CardModel, String>,
        on card: CardModel,
        save: (@escaping () -> Void) -> Void
    ) {
        let previousValue = card[keyPath: keyPath]
        guard previousValue != newValue else {
            return
        }

        let previousUpdatedAt = card.updatedAt
        card[keyPath: keyPath] = newValue
        card.updatedAt = Date()
        save {
            card[keyPath: keyPath] = previousValue
            card.updatedAt = previousUpdatedAt
        }
    }

    static func logSafeSaveErrorDetails(for error: Error) -> (domain: String, code: Int, description: String) {
        let nsError = error as NSError
        return (nsError.domain, nsError.code, error.localizedDescription)
    }

    static func resetActiveParagraph(using onActiveParagraphChange: (Int?) -> Void) {
        onActiveParagraphChange(nil)
    }

    static func prepareForCardChange(
        saveErrorMessage: inout String?,
        using onActiveParagraphChange: (Int?) -> Void
    ) {
        saveErrorMessage = nil
        resetActiveParagraph(using: onActiveParagraphChange)
    }

    static func installUndoManager(_ undoManager: UndoManager?, in context: ModelContext) -> UndoManager? {
        let previousUndoManager = context.undoManager
        context.undoManager = undoManager
        return previousUndoManager
    }

    static func restoreUndoManager(_ undoManager: UndoManager?, in context: ModelContext) {
        context.undoManager = undoManager
    }
}
