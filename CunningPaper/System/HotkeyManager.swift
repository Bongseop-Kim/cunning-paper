import Foundation

enum HotkeyAction: String, CaseIterable {
    case next
    case prev
    case jump
    case nextLine
    case prevLine
    case toggle
    case stop
}

extension KeyboardShortcuts.Name {
    static let next = Self("cunningPaper.next")
    static let prev = Self("cunningPaper.prev")
    static let jump = Self("cunningPaper.jump")
    static let nextLine = Self("cunningPaper.nextLine")
    static let prevLine = Self("cunningPaper.prevLine")
    static let toggle = Self("cunningPaper.toggle")
    static let stop = Self("cunningPaper.stop")
}

extension Notification.Name {
    static let hotkeyFired = Notification.Name("CunningPaper.hotkeyFired")
    static let overlayBoundsChanged = Notification.Name("CunningPaper.overlayBoundsChanged")
}

final class HotkeyManager {
    var onAction: ((HotkeyAction) -> Void)?

    init() {
        register(.next, name: .next)
        register(.prev, name: .prev)
        register(.jump, name: .jump)
        register(.nextLine, name: .nextLine)
        register(.prevLine, name: .prevLine)
        register(.toggle, name: .toggle)
        register(.stop, name: .stop)
        KeyboardShortcuts.startMonitoring()
    }

    deinit {
        KeyboardShortcuts.stopMonitoring()
    }

    private func register(_ action: HotkeyAction, name: KeyboardShortcuts.Name) {
        KeyboardShortcuts.onKeyUp(for: name) { [weak self] in
            self?.onAction?(action)
        }
    }
}
