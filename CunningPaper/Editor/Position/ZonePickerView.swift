import Observation
import SwiftData
import SwiftUI

@Observable
final class ZonePickerState {
    var monitors: [MonitorInfo] = []
    var activeMonitorIndex = 0
    var selectionByMonitor: [Int: DisplayRect] = [:]
    var activePresetKey: String?
    var newPresetLabel = ""

    var activeMonitor: MonitorInfo? {
        monitors[safe: activeMonitorIndex]
    }

    var activeSelection: DisplayRect? {
        get { selectionByMonitor[activeMonitorIndex] }
        set { selectionByMonitor[activeMonitorIndex] = newValue }
    }
}

struct ZonePickerView: View {
    @Environment(\.modelContext) private var context
    @Query private var prefsArray: [PrefsModel]
    @State private var state = ZonePickerState()

    private var prefs: PrefsModel? {
        prefsArray.first
    }

    private var activeCustomPresets: [ZonePreset] {
        guard let monitor = state.activeMonitor else { return [] }
        return ZonePickerPresentation.customPresets(for: monitor, allPresets: prefs?.customPresets ?? [])
    }

    private var currentSummary: String {
        guard let monitor = state.activeMonitor else { return "No position selected" }
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        return ZonePickerPresentation.summaryLabel(
            for: state.activeSelection,
            canvas: CGSize(width: canvas.width, height: canvas.height)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PositionHeaderView(
                monitors: state.monitors,
                selectedMonitorIndex: state.activeMonitorIndex,
                onMonitorSelect: handleMonitorSelect,
                monitor: state.activeMonitor,
                summary: currentSummary
            )

            if let monitor = state.activeMonitor {
                let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)

                VStack(alignment: .leading, spacing: 16) {
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
                            state.activePresetKey = nil
                            applyAndSave(rect: rect, monitor: monitor, canvas: canvas)
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                    QuickPositionBar(
                        presets: ZonePickerPresentation.displayPresets(customPresets: activeCustomPresets),
                        activePresetKey: state.activePresetKey,
                        onSelect: { preset in
                            handleQuickPresetSelect(preset, monitorIndex: state.activeMonitorIndex)
                        },
                        onDelete: { preset in
                            handlePresetDelete(preset.id)
                        }
                    )

                    SavedPositionsView(
                        draftLabel: $state.newPresetLabel,
                        canSave: state.activeSelection != nil,
                        onSave: { saveCurrentSelection() }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                ContentUnavailableView("No display found", systemImage: "display")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
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
            state.activeSelection = selectionFromPrefs(for: monitor)
        }
    }

    private func handleMonitorSelect(_ index: Int) {
        guard state.monitors.indices.contains(index) else { return }
        state.activeMonitorIndex = index
        state.activePresetKey = nil

        guard state.selectionByMonitor[index] == nil, let monitor = state.activeMonitor else { return }
        state.selectionByMonitor[index] = selectionFromPrefs(for: monitor)
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

    private func handleQuickPresetSelect(_ preset: ZonePreset, monitorIndex: Int) {
        handlePresetSelect(monitorIndex: monitorIndex, preset: preset)
    }

    private func handlePresetAdd(monitorIndex: Int, label: String) -> ZonePreset? {
        guard
            let monitor = state.monitors[safe: monitorIndex],
            let prefs,
            let rect = state.selectionByMonitor[monitorIndex]
        else { return nil }

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
        let preset = ZonePreset(
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
        presets.append(preset)
        prefs.customPresets = presets
        try? context.save()
        return preset
    }

    private func saveCurrentSelection() {
        let trimmed = state.newPresetLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let preset = handlePresetAdd(monitorIndex: state.activeMonitorIndex, label: trimmed) {
            state.activePresetKey = "\(state.activeMonitorIndex):\(preset.id)"
        }
        state.newPresetLabel = ""
    }

    private func handlePresetDelete(_ presetID: String) {
        guard let prefs else { return }
        var presets = prefs.customPresets
        presets.removeAll(where: { $0.id == presetID })
        prefs.customPresets = presets
        try? context.save()
    }

    private func selectionFromPrefs(for monitor: MonitorInfo) -> DisplayRect? {
        guard let prefs else { return nil }
        let canvas = ZonePickerMath.placementCanvasSize(monitor: monitor)
        let bounds = PhysicalBounds(
            x: prefs.overlayX,
            y: prefs.overlayY,
            width: prefs.overlayWidth,
            height: prefs.overlayHeight
        )
        let rect = ZonePickerMath.physicalBoundsToDisplayRect(
            bounds: bounds,
            monitor: monitor,
            canvasWidth: canvas.width
        )
        return ZonePickerMath.clamp(rect: rect, canvasWidth: canvas.width, canvasHeight: canvas.height)
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
