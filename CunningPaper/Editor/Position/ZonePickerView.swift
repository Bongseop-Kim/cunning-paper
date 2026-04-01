import Observation
import SwiftData
import SwiftUI

@Observable
final class ZonePickerState {
    var monitors: [MonitorInfo] = []
    var activeMonitorIndex = 0
    var selectionByMonitor: [Int: DisplayRect] = [:]
    var activePresetKey: String?
    var collapsedByMonitor: [Int: Bool] = [:]

    var activeMonitor: MonitorInfo? {
        monitors[safe: activeMonitorIndex]
    }

    var activeSelection: DisplayRect? {
        get { selectionByMonitor[activeMonitorIndex] }
        set { selectionByMonitor[activeMonitorIndex] = newValue }
    }

    func presets(for index: Int, customPresets: [ZonePreset]) -> [ZonePreset] {
        guard let monitor = monitors[safe: index] else { return ZonePreset.builtIns }
        let custom = customPresets.filter { preset in
            if let monitorID = preset.monitorId { return monitorID == monitor.id }
            if let monitorName = preset.monitorName { return monitorName == monitor.name }
            return true
        }
        return ZonePreset.builtIns + custom
    }
}

struct ZonePickerView: View {
    @Environment(\.modelContext) private var context
    @Query private var prefsArray: [PrefsModel]
    @State private var state = ZonePickerState()

    private var prefs: PrefsModel? {
        prefsArray.first
    }

    var body: some View {
        HSplitView {
            PresetListView(
                monitors: state.monitors,
                presetsByMonitor: state.monitors.indices.map { state.presets(for: $0, customPresets: prefs?.customPresets ?? []) },
                activeMonitorIdx: state.activeMonitorIndex,
                activePresetKey: state.activePresetKey,
                collapsedByMonitor: state.collapsedByMonitor,
                onMonitorSelect: { state.activeMonitorIndex = $0 },
                onPresetSelect: handlePresetSelect,
                onPresetAdd: handlePresetAdd,
                onPresetDelete: handlePresetDelete,
                onToggleCollapse: { index in
                    state.collapsedByMonitor[index] = !(state.collapsedByMonitor[index] ?? false)
                }
            )
            .frame(minWidth: 220, maxWidth: 240)

            ZStack {
                if let monitor = state.activeMonitor {
                    let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
                    GridCanvasView(
                        monitor: monitor,
                        canvas: canvas,
                        selection: state.activeSelection,
                        onSelectionChange: { rect in
                            state.activeSelection = rect
                            state.activePresetKey = nil
                        },
                        onSelectionCommit: { rect in
                            state.activeSelection = rect
                            applyAndSave(rect: rect, monitor: monitor, canvas: canvas)
                        }
                    )
                    .padding(24)
                } else {
                    ContentUnavailableView("No display found", systemImage: "display")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            ensurePrefsExists()
            loadMonitors()
        }
    }

    private func ensurePrefsExists() {
        guard prefsArray.isEmpty else { return }
        context.insert(PrefsModel())
        try? context.save()
    }

    private func loadMonitors() {
        let monitors = MonitorInfo.all()
        state.monitors = monitors

        guard let prefs else { return }
        if let index = monitors.firstIndex(where: { monitor in
            CGRect(
                x: CGFloat(monitor.x),
                y: CGFloat(monitor.y),
                width: CGFloat(monitor.width),
                height: CGFloat(monitor.height)
            )
            .intersects(prefs.overlayFrame)
        }) {
            state.activeMonitorIndex = index
        }

        if let monitor = state.activeMonitor {
            let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
            let bounds = PhysicalBounds(
                x: prefs.overlayX,
                y: prefs.overlayY,
                width: prefs.overlayWidth,
                height: prefs.overlayHeight
            )
            state.activeSelection = ZonePickerMath.physicalBoundsToDisplayRect(
                bounds: bounds,
                monitor: monitor,
                canvasWidth: canvas.width
            )
        }
    }

    private func handlePresetSelect(monitorIndex: Int, preset: ZonePreset) {
        guard let monitor = state.monitors[safe: monitorIndex] else { return }
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        let dims = GridMath.calcGridDimensions(monitorW: monitor.width, monitorH: monitor.height)
        let rect = GridMath.presetRatioToDisplayRect(
            px: preset.x,
            py: preset.y,
            pw: preset.w,
            ph: preset.h,
            cols: dims.cols,
            rows: dims.rows,
            canvasW: canvas.width,
            canvasH: canvas.height
        )
        state.activeMonitorIndex = monitorIndex
        state.activeSelection = rect
        state.activePresetKey = "\(monitorIndex):\(preset.id)"
        applyAndSave(rect: rect, monitor: monitor, canvas: canvas)
    }

    private func handlePresetAdd(monitorIndex: Int, label: String) {
        guard
            let monitor = state.monitors[safe: monitorIndex],
            let prefs,
            let rect = state.selectionByMonitor[monitorIndex]
        else { return }

        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        let dims = GridMath.calcGridDimensions(monitorW: monitor.width, monitorH: monitor.height)
        let ratio = GridMath.displayRectToPresetRatio(
            rect: rect,
            cols: dims.cols,
            rows: dims.rows,
            canvasW: canvas.width,
            canvasH: canvas.height
        )
        var presets = prefs.customPresets
        presets.append(
            ZonePreset(
                id: UUID().uuidString,
                label: label,
                x: ratio.x,
                y: ratio.y,
                w: ratio.w,
                h: ratio.h,
                builtIn: false,
                monitorId: monitor.id,
                monitorName: monitor.name
            )
        )
        prefs.customPresets = presets
        try? context.save()
    }

    private func handlePresetDelete(_ presetID: String) {
        guard let prefs else { return }
        var presets = prefs.customPresets
        presets.removeAll(where: { $0.id == presetID })
        prefs.customPresets = presets
        try? context.save()
    }

    private func applyAndSave(
        rect: DisplayRect,
        monitor: MonitorInfo,
        canvas: (width: CGFloat, height: CGFloat, scale: CGFloat)
    ) {
        let bounds = ZonePickerMath.displayRectToPhysicalBounds(
            rect: rect,
            monitor: monitor,
            canvasWidth: canvas.width
        )

        NotificationCenter.default.post(name: .overlayBoundsChanged, object: bounds)

        if let prefs {
            prefs.overlayX = bounds.x
            prefs.overlayY = bounds.y
            prefs.overlayWidth = bounds.width
            prefs.overlayHeight = bounds.height
            try? context.save()
        }
    }
}
