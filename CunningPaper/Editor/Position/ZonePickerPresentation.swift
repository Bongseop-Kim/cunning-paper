import CoreGraphics

enum ZonePickerPresentation {
    static let quickPresets: [ZonePreset] = [
        .init(id: "full", label: "Full Screen", x: 0, y: 0, w: 1, h: 1, builtIn: true),
        .init(id: "left", label: "Left Half", x: 0, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "right", label: "Right Half", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "top", label: "Top Half", x: 0, y: 0, w: 1, h: 0.5, builtIn: true),
        .init(id: "bottom", label: "Bottom Half", x: 0, y: 0.5, w: 1, h: 0.5, builtIn: true),
        .init(id: "center", label: "Centered", x: 0.2, y: 0.2, w: 0.6, h: 0.6, builtIn: true),
    ]

    static func displayPresets(customPresets: [ZonePreset]) -> [ZonePreset] {
        Array(customPresets.reversed()) + quickPresets
    }

    static func customPresets(for monitor: MonitorInfo, allPresets: [ZonePreset]) -> [ZonePreset] {
        allPresets.filter { preset in
            guard !preset.builtIn else { return false }
            if let monitorID = preset.monitorId { return monitorID == monitor.id }
            if let monitorName = preset.monitorName { return monitorName == monitor.name }
            return true
        }
    }

    static func summaryLabel(for rect: DisplayRect?, canvas: CGSize) -> String {
        guard let rect, rect.w > 0, rect.h > 0, canvas.width > 0, canvas.height > 0 else {
            return "No position selected"
        }

        let ratioPreset = ZonePreset(
            id: "current",
            label: "Current",
            x: rect.x / canvas.width,
            y: rect.y / canvas.height,
            w: rect.w / canvas.width,
            h: rect.h / canvas.height,
            builtIn: true
        )

        if let match = quickPresets.first(where: { preset in
            abs(preset.x - ratioPreset.x) < 0.05 &&
            abs(preset.y - ratioPreset.y) < 0.05 &&
            abs(preset.w - ratioPreset.w) < 0.05 &&
            abs(preset.h - ratioPreset.h) < 0.05
        }) {
            return match.label
        }

        return "Custom"
    }
}
