import SwiftUI

struct SearchPanelView: View {
    let cards: [CardModel]
    let onSelect: (CardModel) -> Void
    let onClose: () -> Void

    @State private var query = ""
    @FocusState private var focused: Bool

    private var results: [CardModel] {
        guard !query.isEmpty else { return cards }
        let needle = query.lowercased()
        return cards.filter {
            $0.title.lowercased().contains(needle) || $0.body.lowercased().contains(needle)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search cards", text: $query)
                    .textFieldStyle(.plain)
                    .focused($focused)
                Button("Close", action: onClose)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { card in
                        Button {
                            onSelect(card)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.title.isEmpty ? "Untitled" : card.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(card.paragraphs.first ?? card.body)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .frame(width: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onAppear { focused = true }
    }
}
