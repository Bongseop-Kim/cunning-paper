import SwiftUI

struct PresetListView: View {
    let monitors: [MonitorInfo]
    let presetsByMonitor: [[ZonePreset]]
    let activeMonitorIdx: Int
    let activePresetKey: String?
    let collapsedByMonitor: [Int: Bool]
    let onMonitorSelect: (Int) -> Void
    let onPresetSelect: (Int, ZonePreset) -> Void
    let onPresetAdd: (Int, String) -> Void
    let onPresetDelete: (String) -> Void
    let onToggleCollapse: (Int) -> Void

    @State private var addTargetMonitor: Int?
    @State private var addLabel = ""

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(monitors.enumerated()), id: \.offset) { index, monitor in
                    monitorSection(index: index, monitor: monitor)
                }
            }
        }
    }

    private func monitorSection(index: Int, monitor: MonitorInfo) -> some View {
        let collapsed = collapsedByMonitor[index] ?? false
        let presets = presetsByMonitor[safe: index] ?? []
        let customPresets = presets.filter { !$0.builtIn }

        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    onMonitorSelect(index)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(monitor.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("\(monitor.width) × \(monitor.height) • \(monitor.orientationLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button {
                    onToggleCollapse(index)
                } label: {
                    Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(activeMonitorIdx == index ? Color.accentColor.opacity(0.08) : Color.clear)

            if !collapsed {
                VStack(spacing: 4) {
                    ForEach(presets) { preset in
                        presetRow(index: index, preset: preset)
                    }

                    HStack(spacing: 8) {
                        if addTargetMonitor == index {
                            TextField("Preset name", text: $addLabel)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { submitNewPreset(for: index) }
                        }

                        Button(addTargetMonitor == index ? "Save" : "New Preset") {
                            if addTargetMonitor == index {
                                submitNewPreset(for: index)
                            } else {
                                addTargetMonitor = index
                                addLabel = ""
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    if !customPresets.isEmpty {
                        Divider().padding(.horizontal, 12)
                    }
                }
                .padding(.bottom, 10)
            }

            Divider()
        }
    }

    private func presetRow(index: Int, preset: ZonePreset) -> some View {
        let key = "\(index):\(preset.id)"

        return HStack(spacing: 8) {
            Button {
                onPresetSelect(index, preset)
            } label: {
                HStack(spacing: 8) {
                    presetThumbnail(preset: preset, isVertical: monitors[safe: index]?.isVertical ?? false)
                    Text(preset.label)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            if !preset.builtIn {
                Button(role: .destructive) {
                    onPresetDelete(preset.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(activePresetKey == key ? Color.accentColor.opacity(0.14) : Color.clear)
    }

    private func presetThumbnail(preset: ZonePreset, isVertical: Bool) -> some View {
        let width: CGFloat = isVertical ? 16 : 26
        let height: CGFloat = isVertical ? 26 : 16

        return Canvas { context, size in
            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2),
                with: .color(.secondary.opacity(0.15))
            )
            let zone = CGRect(
                x: preset.x * size.width,
                y: preset.y * size.height,
                width: preset.w * size.width,
                height: preset.h * size.height
            )
            context.fill(Path(roundedRect: zone, cornerRadius: 1), with: .color(.primary))
        }
        .frame(width: width, height: height)
    }

    private func submitNewPreset(for index: Int) {
        let trimmed = addLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onPresetAdd(index, trimmed)
        addTargetMonitor = nil
        addLabel = ""
    }
}
