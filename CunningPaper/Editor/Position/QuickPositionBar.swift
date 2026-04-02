import SwiftUI

struct QuickPositionBar: View {
    let presets: [ZonePreset]
    let activePresetKey: String?
    let onSelect: (ZonePreset) -> Void
    let onDelete: ((ZonePreset) -> Void)?

    private let cardContentHeight: CGFloat = 72

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

                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(backgroundColor(for: preset, isActive: isActive))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(borderColor(for: preset, isActive: isActive), lineWidth: 1)
                            )

                        Button {
                            onSelect(preset)
                        } label: {
                            GeometryReader { proxy in
                                let layout = ZonePickerPresentation.quickPresetPreviewLayout(
                                    availableWidth: proxy.size.width,
                                    availableHeight: cardContentHeight
                                )

                                quickPositionContent(
                                    for: preset,
                                    layout: layout,
                                    isActive: isActive
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .frame(minHeight: cardContentHeight)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        if !preset.builtIn, let onDelete {
                            Button {
                                onDelete(preset)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 22, height: 22)
                                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.95), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .padding(6)
                            .accessibilityLabel("Delete \(preset.label)")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func quickPositionContent(
        for preset: ZonePreset,
        layout: QuickPresetPreviewLayout,
        isActive: Bool
    ) -> some View {
        switch layout {
        case .topThumbnail:
            VStack(alignment: .leading, spacing: 6) {
                PresetPreviewView(preset: preset, layout: layout, isActive: isActive)
                quickPositionLabelBlock(for: preset)
            }
        case .sideIcon:
            HStack(alignment: .center, spacing: 10) {
                PresetPreviewView(preset: preset, layout: layout, isActive: isActive)
                quickPositionLabelBlock(for: preset)
            }
        }
    }

    private func quickPositionLabelBlock(for preset: ZonePreset) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if !preset.builtIn {
                Text("Saved")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(preset.label)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private func backgroundColor(for preset: ZonePreset, isActive: Bool) -> Color {
        if isActive {
            return Color.accentColor.opacity(preset.builtIn ? 0.18 : 0.24)
        }

        if preset.builtIn {
            return Color(nsColor: .controlBackgroundColor)
        }

        return Color.accentColor.opacity(0.08)
    }

    private func borderColor(for preset: ZonePreset, isActive: Bool) -> Color {
        if isActive {
            return Color.accentColor.opacity(0.6)
        }

        if preset.builtIn {
            return Color.primary.opacity(0.08)
        }

        return Color.accentColor.opacity(0.24)
    }
}
