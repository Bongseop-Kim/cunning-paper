import SwiftUI

struct SavedPositionsView: View {
    let presets: [ZonePreset]
    @Binding var draftLabel: String
    let canSave: Bool
    let onSave: () -> Void
    let onSelect: (ZonePreset) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Positions")
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

            if presets.isEmpty {
                Text("No saved positions for this monitor yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(presets) { preset in
                        HStack(spacing: 8) {
                            Button(preset.label) {
                                onSelect(preset)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(role: .destructive) {
                                onDelete(preset.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}
