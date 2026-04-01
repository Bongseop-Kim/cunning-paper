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

    private static var handlers: [Name: () -> Void] = [:]

    static func onKeyUp(for name: Name, action: @escaping () -> Void) {
        handlers[name] = action
    }

    static func trigger(_ name: Name) {
        handlers[name]?()
    }

    static func reset(_ names: Name...) {
        let defaults = UserDefaults.standard
        names.forEach { defaults.removeObject(forKey: storageKey(for: $0)) }
    }

    static func shortcutString(for name: Name) -> String {
        UserDefaults.standard.string(forKey: storageKey(for: name)) ?? ""
    }

    static func setShortcutString(_ value: String, for name: Name) {
        UserDefaults.standard.set(value, forKey: storageKey(for: name))
    }

    private static func storageKey(for name: Name) -> String {
        "KeyboardShortcuts.\(name.rawValue)"
    }

    struct Recorder: View {
        let name: Name
        @State private var value: String = ""

        init(for name: Name) {
            self.name = name
        }

        var body: some View {
            TextField("Shortcut", text: $value)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onAppear {
                    value = KeyboardShortcuts.shortcutString(for: name)
                }
                .onSubmit {
                    KeyboardShortcuts.setShortcutString(value, for: name)
                }
        }
    }
}
