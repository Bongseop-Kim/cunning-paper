import SwiftUI

struct JumpPanelView: View {
    let totalCards: Int
    let onJump: (Int) -> Void
    let onClose: () -> Void

    @State private var input = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text("Jump to card")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("1-\(max(totalCards, 1))", text: $input)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .frame(width: 120)
                .focused($focused)
                .onSubmit(commit)
            Button("Close", role: .cancel, action: onClose)
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .onAppear { focused = true }
    }

    private func commit() {
        guard let value = Int(input), value >= 1, value <= totalCards else {
            onClose()
            return
        }
        onJump(value - 1)
    }
}
