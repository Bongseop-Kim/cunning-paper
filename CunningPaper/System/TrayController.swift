import AppKit

@MainActor
final class TrayController: NSObject {
    private let statusItem: NSStatusItem
    private weak var coordinator: AppCoordinator?

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "CunningPaper")
        statusItem.button?.image?.isTemplate = true
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Show or Hide Overlay", action: #selector(toggleOverlay), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let openEditorItem = NSMenuItem(title: "Open Editor", action: #selector(openEditor), keyEquivalent: "")
        openEditorItem.target = self
        menu.addItem(openEditorItem)

        menu.addItem(.separator())

        let positionMenu = NSMenu(title: "Position")
        for preset in ZonePreset.builtIns {
            let item = NSMenuItem(title: preset.label, action: #selector(applyPreset(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset
            positionMenu.addItem(item)
        }
        let positionItem = NSMenuItem(title: "Position", action: nil, keyEquivalent: "")
        positionItem.submenu = positionMenu
        menu.addItem(positionItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func toggleOverlay() {
        coordinator?.toggleOverlay()
    }

    @objc private func openEditor() {
        coordinator?.showEditor()
    }

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard let preset = sender.representedObject as? ZonePreset else { return }
        coordinator?.applyPreset(preset)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
