import AppKit
import Observation
import SwiftData

@MainActor
@Observable
final class AppCoordinator {
    private(set) var overlayPanel: OverlayPanel?
    private var trayController: TrayController?
    private var hotkeyManager: HotkeyManager?
    private var modelContainer: ModelContainer?
    private var boundsObserver: NSObjectProtocol?

    func setup(modelContainer: ModelContainer) {
        guard self.modelContainer == nil else { return }
        self.modelContainer = modelContainer

        let context = ModelContext(modelContainer)
        MigrationService.runIfNeeded(context: context)
        ensurePrefsExists(in: context)

        let panel = OverlayPanel(modelContainer: modelContainer)
        restoreOverlayBounds(panel: panel, context: context)
        panel.orderFront(nil)
        panel.ignoresMouseEvents = true
        overlayPanel = panel

        let hotkeyManager = HotkeyManager()
        hotkeyManager.onAction = { [weak self] action in
            guard let self else { return }
            if action == .toggle {
                self.toggleOverlay()
                return
            }

            NotificationCenter.default.post(
                name: .hotkeyFired,
                object: nil,
                userInfo: ["action": action.rawValue]
            )
        }
        self.hotkeyManager = hotkeyManager

        trayController = TrayController(coordinator: self)

        boundsObserver = NotificationCenter.default.addObserver(
            forName: .overlayBoundsChanged,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let bounds = note.object as? PhysicalBounds else { return }
            let frame = CGRect(x: bounds.x, y: bounds.y, width: bounds.width, height: bounds.height)
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.overlayPanel?.setFrame(frame, display: true)
                self.saveOverlayFrame(frame)
            }
        }
    }

    func showEditor() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { !($0 is OverlayPanel) }) ?? NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func toggleOverlay() {
        guard let panel = overlayPanel else { return }
        if panel.isVisible {
            panel.fadeOut()
        } else {
            panel.fadeIn()
        }
    }

    func applyPreset(_ preset: ZonePreset) {
        guard let panel = overlayPanel else { return }
        let targetScreen = NSScreen.main ?? NSScreen.screens.first
        guard let screen = targetScreen else { return }
        let screenFrame = screen.visibleFrame
        let frame = CGRect(
            x: screenFrame.origin.x + (screenFrame.width * preset.x),
            y: screenFrame.origin.y + (screenFrame.height * preset.y),
            width: screenFrame.width * preset.w,
            height: screenFrame.height * preset.h
        )
        panel.setFrame(frame, display: true)
        saveOverlayFrame(frame)
    }

    private func ensurePrefsExists(in context: ModelContext) {
        let descriptor = FetchDescriptor<PrefsModel>()
        if (try? context.fetch(descriptor).isEmpty) == true {
            context.insert(PrefsModel())
            try? context.save()
        }
    }

    private func saveOverlayFrame(_ frame: CGRect) {
        guard let modelContainer else { return }
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<PrefsModel>()
        guard let prefs = try? context.fetch(descriptor).first else { return }
        prefs.overlayFrame = frame
        try? context.save()
    }

    private func restoreOverlayBounds(panel: OverlayPanel, context: ModelContext) {
        let descriptor = FetchDescriptor<PrefsModel>()
        guard let prefs = try? context.fetch(descriptor).first else { return }
        let frame = prefs.overlayFrame
        guard frame.width > 0, frame.height > 0 else { return }

        let onScreen = NSScreen.screens.contains { $0.frame.intersects(frame) }
        if onScreen {
            panel.setFrame(frame, display: false)
        } else {
            panel.center()
        }
    }
}
