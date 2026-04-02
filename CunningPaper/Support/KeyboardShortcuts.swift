import AppKit
import Carbon
import SwiftUI

enum KeyboardShortcuts {
    struct Name: Hashable, RawRepresentable, ExpressibleByStringLiteral {
        let rawValue: String

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(stringLiteral value: StringLiteralType) {
            rawValue = value
        }

        init(_ rawValue: String) {
            self.rawValue = rawValue
        }
    }

    struct Shortcut: Equatable {
        let keyCode: UInt16
        let modifiers: NSEvent.ModifierFlags

        static func from(_ string: String) -> Shortcut? {
            let parts = string.split(separator: ",")
            guard parts.count == 2,
                  let flagsRaw = UInt(parts[0]),
                  let code = UInt16(parts[1])
            else { return nil }
            return Shortcut(
                keyCode: code,
                modifiers: NSEvent.ModifierFlags(rawValue: flagsRaw)
            )
        }

        var storageString: String {
            let cleaned = modifiers.intersection([.command, .option, .shift, .control])
            return "\(cleaned.rawValue),\(keyCode)"
        }

        var displayString: String {
            var s = ""
            let m = modifiers.intersection([.command, .option, .shift, .control])
            if m.contains(.control) { s += "⌃" }
            if m.contains(.option) { s += "⌥" }
            if m.contains(.shift) { s += "⇧" }
            if m.contains(.command) { s += "⌘" }
            s += KeyCodeMap.label(for: keyCode)
            return s
        }
    }

    private static var handlers: [Name: () -> Void] = [:]
    private static var hotKeyRefs: [Name: EventHotKeyRef] = [:]
    private static var nameForID: [UInt32: Name] = [:]
    private static var nextID: UInt32 = 1
    private static var carbonEventHandler: EventHandlerRef?

    static func onKeyUp(for name: Name, action: @escaping () -> Void) {
        handlers[name] = action
    }

    static func trigger(_ name: Name) {
        handlers[name]?()
    }

    static func startMonitoring() {
        installCarbonEventHandler()
        for name in handlers.keys {
            _ = registerHotKey(for: name)
        }
    }

    static func stopMonitoring() {
        hotKeyRefs.values.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()
        nameForID.removeAll()
        if let h = carbonEventHandler { RemoveEventHandler(h); carbonEventHandler = nil }
    }

    private static func installCarbonEventHandler() {
        guard carbonEventHandler == nil else { return }
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyReleased)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }
                var hkID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                let id = hkID.id
                DispatchQueue.main.async {
                    if let name = KeyboardShortcuts.nameForID[id] {
                        KeyboardShortcuts.trigger(name)
                    }
                }
                return noErr
            },
            1, &spec, nil, &carbonEventHandler
        )
    }

    private static func unregisterHotKey(for name: Name) {
        if let existing = hotKeyRefs[name] {
            UnregisterEventHotKey(existing)
            hotKeyRefs.removeValue(forKey: name)
        }
        nameForID = nameForID.filter { $0.value != name }
    }

    @discardableResult
    private static func registerHotKey(for name: Name) -> Bool {
        unregisterHotKey(for: name)
        guard let sc = Shortcut.from(shortcutString(for: name)) else { return true }

        var id = EventHotKeyID()
        id.signature = "cpap".utf8.prefix(4).reduce(0) { $0 << 8 | FourCharCode($1) }
        id.id = nextID
        nextID += 1

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(sc.keyCode),
            carbonModifiers(from: sc.modifiers),
            id,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else {
            unregisterHotKey(for: name)
            return false
        }
        hotKeyRefs[name] = ref
        nameForID[id.id] = name
        return true
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var c: UInt32 = 0
        if flags.contains(.command) { c |= UInt32(cmdKey) }
        if flags.contains(.option)  { c |= UInt32(optionKey) }
        if flags.contains(.shift)   { c |= UInt32(shiftKey) }
        if flags.contains(.control) { c |= UInt32(controlKey) }
        return c
    }

    static func reset(_ names: Name...) {
        let defaults = UserDefaults.standard
        for name in names {
            defaults.removeObject(forKey: storageKey(for: name))
            unregisterHotKey(for: name)
        }
    }

    static func shortcutString(for name: Name) -> String {
        UserDefaults.standard.string(forKey: storageKey(for: name)) ?? ""
    }

    @discardableResult
    static func setShortcutString(_ value: String, for name: Name) -> Bool {
        let defaults = UserDefaults.standard
        let key = storageKey(for: name)
        let previousValue = defaults.string(forKey: key)

        defaults.set(value, forKey: key)
        guard registerHotKey(for: name) else {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
            _ = registerHotKey(for: name)
            NSSound.beep()
            return false
        }
        return true
    }

    private static func storageKey(for name: Name) -> String {
        "KeyboardShortcuts.\(name.rawValue)"
    }

    struct Recorder: View {
        let name: Name
        @State private var shortcut: Shortcut?

        init(for name: Name) {
            self.name = name
        }

        var body: some View {
            ShortcutRecorderField(shortcut: $shortcut)
                .frame(height: 28)
                .onAppear {
                    shortcut = Shortcut.from(KeyboardShortcuts.shortcutString(for: name))
                }
                .onChange(of: shortcut) { _, newValue in
                    if let sc = newValue {
                        guard KeyboardShortcuts.setShortcutString(sc.storageString, for: name) else {
                            shortcut = Shortcut.from(KeyboardShortcuts.shortcutString(for: name))
                            return
                        }
                    } else {
                        KeyboardShortcuts.reset(name)
                    }
                }
        }
    }
}

// MARK: - ShortcutRecorderField

private struct ShortcutRecorderField: NSViewRepresentable {
    @Binding var shortcut: KeyboardShortcuts.Shortcut?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        let coordinator = context.coordinator
        view.onShortcutChanged = { sc in
            coordinator.parent.shortcut = sc
        }
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        context.coordinator.parent = self
        if nsView.shortcut != shortcut {
            nsView.shortcut = shortcut
        }
    }

    final class Coordinator {
        var parent: ShortcutRecorderField
        init(_ parent: ShortcutRecorderField) { self.parent = parent }
    }
}

// MARK: - KeyRecorderNSView

private final class KeyRecorderNSView: NSView {
    var shortcut: KeyboardShortcuts.Shortcut? { didSet { needsDisplay = true } }
    var onShortcutChanged: ((KeyboardShortcuts.Shortcut?) -> Void)?

    private var isRecording = false { didSet { needsDisplay = true } }

    // Key codes that are modifier-only (command, shift, option, control, fn, caps lock)
    private static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: 28) }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        focusRingType = .none
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { isRecording = true }
        return result
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if shortcut != nil, !isRecording, clearButtonRect.contains(point) {
            shortcut = nil
            onShortcutChanged?(nil)
            return
        }
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }

        if event.keyCode == 53 { // Escape cancels recording
            window?.makeFirstResponder(nil)
            return
        }

        guard !Self.modifierKeyCodes.contains(event.keyCode) else { return }

        let mods = event.modifierFlags.intersection([.command, .option, .shift, .control])
        guard !mods.isEmpty else {
            NSSound.beep()
            return
        }
        let sc = KeyboardShortcuts.Shortcut(keyCode: event.keyCode, modifiers: mods)
        shortcut = sc
        onShortcutChanged?(sc)
        window?.makeFirstResponder(nil)
    }

    private var clearButtonRect: NSRect {
        let size: CGFloat = 14
        return NSRect(x: bounds.width - size - 7, y: (bounds.height - size) / 2, width: size, height: size)
    }

    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)

        if isRecording {
            NSColor.controlAccentColor.withAlphaComponent(0.1).setFill()
            NSColor.controlAccentColor.setStroke()
        } else {
            NSColor.controlBackgroundColor.setFill()
            NSColor.separatorColor.setStroke()
        }
        path.fill()
        path.lineWidth = 1
        path.stroke()

        let label: String
        let labelColor: NSColor

        if isRecording {
            label = "Press shortcut…"
            labelColor = NSColor.secondaryLabelColor
        } else if let sc = shortcut {
            label = sc.displayString
            labelColor = NSColor.labelColor
        } else {
            label = "Click to record"
            labelColor = NSColor.tertiaryLabelColor
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: labelColor,
        ]
        let attrStr = NSAttributedString(string: label, attributes: attrs)
        let labelSize = attrStr.size()
        let labelX = (bounds.width - labelSize.width) / 2
        let labelY = (bounds.height - labelSize.height) / 2
        attrStr.draw(at: NSPoint(x: max(8, labelX), y: labelY))

        if !isRecording, shortcut != nil {
            let xRect = clearButtonRect
            NSColor.quaternaryLabelColor.setFill()
            NSBezierPath(ovalIn: xRect).fill()

            let xAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 8, weight: .bold),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
            let xStr = NSAttributedString(string: "✕", attributes: xAttrs)
            let xSize = xStr.size()
            xStr.draw(at: NSPoint(x: xRect.midX - xSize.width / 2, y: xRect.midY - xSize.height / 2))
        }
    }
}

// MARK: - KeyCodeMap

private enum KeyCodeMap {
    static func label(for keyCode: UInt16) -> String {
        switch keyCode {
        // Letters
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        // Numbers
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        // Special keys
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 117: return "⌦"
        // Arrow keys
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        // Function keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        // Punctuation
        case 30: return "]"
        case 33: return "["
        case 39: return "'"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 47: return "."
        // Navigation
        case 115: return "↖"
        case 116: return "⇞"
        case 119: return "↘"
        case 121: return "⇟"
        default: return "?"
        }
    }
}
