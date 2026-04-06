import Foundation
import SwiftData

struct HotkeyConfig: Codable, Equatable {
    var next: String
    var prev: String
    var jump: String
    var nextLine: String
    var prevLine: String
    var toggle: String

    static let `default` = HotkeyConfig(
        next: "control+right",
        prev: "control+left",
        jump: "control+g",
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

private enum PrefsDefaults {
    static let readingModeRaw = ReadingMode.voiceTracking.rawValue
    static let autoScrollSpeed = 3.0
    static let speechLanguage = "ko-KR"
}

extension CunningPaperSchemaV1 {
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
}

extension CunningPaperSchemaV2 {
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
        var readingModeRaw: String?
        var autoScrollSpeed: Double?
        var speechLanguage: String?

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
            readingModeRaw = PrefsDefaults.readingModeRaw
            autoScrollSpeed = PrefsDefaults.autoScrollSpeed
            speechLanguage = PrefsDefaults.speechLanguage
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
}

extension CunningPaperSchemaV3 {
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
        var readingModeRaw: String
        var autoScrollSpeed: Double
        var speechLanguage: String

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
            readingModeRaw = PrefsDefaults.readingModeRaw
            autoScrollSpeed = PrefsDefaults.autoScrollSpeed
            speechLanguage = PrefsDefaults.speechLanguage
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

        var readingMode: ReadingMode {
            get { ReadingMode(rawValue: readingModeRaw) ?? .voiceTracking }
            set { readingModeRaw = newValue.rawValue }
        }
    }
}

enum CunningPaperMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            CunningPaperSchemaV1.self,
            CunningPaperSchemaV2.self,
            CunningPaperSchemaV3.self,
        ]
    }

    static var stages: [MigrationStage] {
        [
            .custom(
                fromVersion: CunningPaperSchemaV1.self,
                toVersion: CunningPaperSchemaV2.self,
                willMigrate: nil,
                didMigrate: { context in
                    let descriptor = FetchDescriptor<CunningPaperSchemaV2.PrefsModel>()
                    let prefs = try context.fetch(descriptor)

                    for pref in prefs {
                        pref.readingModeRaw = pref.readingModeRaw ?? PrefsDefaults.readingModeRaw
                        pref.autoScrollSpeed = pref.autoScrollSpeed ?? PrefsDefaults.autoScrollSpeed
                        pref.speechLanguage = pref.speechLanguage ?? PrefsDefaults.speechLanguage
                    }

                    try context.save()
                }
            ),
            .lightweight(
                fromVersion: CunningPaperSchemaV2.self,
                toVersion: CunningPaperSchemaV3.self
            ),
        ]
    }
}

typealias PrefsModel = CunningPaperSchemaV3.PrefsModel
