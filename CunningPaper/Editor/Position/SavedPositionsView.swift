import SwiftUI

struct SavedPositionsView: View {
    @Binding var draftLabel: String
    let canSave: Bool
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save Current Position")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                TextField("Name", text: $draftLabel)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)

                Button("Save Current") {
                    onSave()
                }
                .disabled(!canSave)
            }

            Text("Saved layouts appear in Quick Positions so they are easier to reuse and remove.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
