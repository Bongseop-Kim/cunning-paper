import SwiftUI

struct PresetPreviewView: View {
    let preset: ZonePreset
    let layout: QuickPresetPreviewLayout
    let isActive: Bool

    var body: some View {
        let frame = ZonePickerPresentation.quickPresetPreviewFrame(for: layout)

        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )

            GeometryReader { proxy in
                let insetX = proxy.size.width * 0.06
                let insetY = proxy.size.height * 0.10
                let width = proxy.size.width - (insetX * 2)
                let height = proxy.size.height - (insetY * 2)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isActive ? Color.accentColor : Color.accentColor.opacity(0.65))
                    .frame(
                        width: width * preset.w,
                        height: height * preset.h
                    )
                    .position(
                        x: insetX + (width * preset.x) + ((width * preset.w) / 2),
                        y: insetY + (height * preset.y) + ((height * preset.h) / 2)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .frame(width: frame.width, height: frame.height)
        .accessibilityHidden(true)
    }
}
