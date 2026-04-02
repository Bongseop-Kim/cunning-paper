import SwiftUI

struct QuickPositionBar: View {
    let presets: [ZonePreset]
    let activePresetKey: String?
    let onSelect: (ZonePreset) -> Void

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 10, alignment: .leading)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Positions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(presets) { preset in
                    let isActive = activePresetKey?.hasSuffix(":\(preset.id)") == true

                    Button {
                        onSelect(preset)
                    } label: {
                        Text(preset.label)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .padding(.horizontal, 12)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isActive ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isActive ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }
}
