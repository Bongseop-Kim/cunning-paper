import Foundation
import SwiftData

struct HotkeyConfig: Codable, Equatable {
    var next: String
    var prev: String
    var jump: String
    var search: String
    var nextLine: String
    var prevLine: String
    var toggle: String

    static let `default` = HotkeyConfig(
        next: "control+right",
        prev: "control+left",
        jump: "control+g",
        search: "control+f",
        nextLine: "control+down",
        prevLine: "control+up",
        toggle: "control+shift+o"
    )
}

struct ZonePreset: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var builtIn: Bool
    var monitorId: String?
    var monitorName: String?

    static let builtIns: [ZonePreset] = [
        .init(id: "left", label: "Left", x: 0, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "right", label: "Right", x: 0.5, y: 0, w: 0.5, h: 1, builtIn: true),
        .init(id: "top", label: "Top", x: 0, y: 0, w: 1, h: 0.5, builtIn: true),
        .init(id: "bottom", label: "Bottom", x: 0, y: 0.5, w: 1, h: 0.5, builtIn: true),
        .init(id: "top-left", label: "Top Left", x: 0, y: 0, w: 0.5, h: 0.5, builtIn: true),
        .init(id: "top-right", label: "Top Right", x: 0.5, y: 0, w: 0.5, h: 0.5, builtIn: true),
        .init(id: "bottom-left", label: "Bottom Left", x: 0, y: 0.5, w: 0.5, h: 0.5, builtIn: true),
        .init(id: "bottom-right", label: "Bottom Right", x: 0.5, y: 0.5, w: 0.5, h: 0.5, builtIn: true),
        .init(id: "top-third", label: "Top Third", x: 0, y: 0, w: 1, h: 1.0 / 3.0, builtIn: true),
        .init(id: "mid-third", label: "Middle Third", x: 0, y: 1.0 / 3.0, w: 1, h: 1.0 / 3.0, builtIn: true),
        .init(id: "bottom-third", label: "Bottom Third", x: 0, y: 2.0 / 3.0, w: 1, h: 1.0 / 3.0, builtIn: true),
    ]
}

@Model
final class PrefsModel {
    var overlayX: Double
    var overlayY: Double
    var overlayWidth: Double
    var overlayHeight: Double
    var fontSize: Double
    var lineHeight: Double
    var opacity: Double
    var highlightCurrentParagraph: Bool
    var hotkeysData: Data
    var customPresetsData: Data

    init() {
        overlayX = 80
        overlayY = 80
        overlayWidth = 520
        overlayHeight = 180
        fontSize = 24
        lineHeight = 1.6
        opacity = 0.85
        highlightCurrentParagraph = true
        hotkeysData = (try? JSONEncoder().encode(HotkeyConfig.default)) ?? Data()
        customPresetsData = (try? JSONEncoder().encode([ZonePreset]())) ?? Data()
    }

    var hotkeys: HotkeyConfig {
        get { (try? JSONDecoder().decode(HotkeyConfig.self, from: hotkeysData)) ?? .default }
        set { hotkeysData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var customPresets: [ZonePreset] {
        get { (try? JSONDecoder().decode([ZonePreset].self, from: customPresetsData)) ?? [] }
        set { customPresetsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var overlayFrame: CGRect {
        get {
            CGRect(x: overlayX, y: overlayY, width: overlayWidth, height: overlayHeight)
        }
        set {
            overlayX = newValue.origin.x
            overlayY = newValue.origin.y
            overlayWidth = newValue.width
            overlayHeight = newValue.height
        }
    }
}
