import SwiftData
import SwiftUI

struct PreferencesView: View {
    @Environment(\.modelContext) private var context
    @Query private var prefsArray: [PrefsModel]

    var body: some View {
        ScrollView {
            if let prefs = prefsArray.first {
                VStack(alignment: .leading, spacing: 24) {
                    GroupBox("Appearance") {
                        VStack(spacing: 14) {
                            LabeledContent("Font Size \(Int(prefs.fontSize))") {
                                Slider(
                                    value: Binding(
                                        get: { prefs.fontSize },
                                        set: {
                                            prefs.fontSize = $0
                                            try? context.save()
                                        }
                                    ),
                                    in: 14...40,
                                    step: 1
                                )
                            }

                            LabeledContent("Opacity \(Int(prefs.opacity * 100))%") {
                                Slider(
                                    value: Binding(
                                        get: { prefs.opacity },
                                        set: {
                                            prefs.opacity = $0
                                            try? context.save()
                                        }
                                    ),
                                    in: 0.35...1.0,
                                    step: 0.05
                                )
                            }

                            Toggle(
                                "Highlight current paragraph",
                                isOn: Binding(
                                    get: { prefs.highlightCurrentParagraph },
                                    set: {
                                        prefs.highlightCurrentParagraph = $0
                                        try? context.save()
                                    }
                                )
                            )
                        }
                        .padding(4)
                    }

                    GroupBox("Shortcuts") {
                        VStack(alignment: .leading, spacing: 10) {
                            shortcutRow("Next Card", name: .next)
                            shortcutRow("Previous Card", name: .prev)
                            shortcutRow("Jump", name: .jump)
                            shortcutRow("Search", name: .search)
                            shortcutRow("Next Paragraph", name: .nextLine)
                            shortcutRow("Previous Paragraph", name: .prevLine)
                            shortcutRow("Toggle Overlay", name: .toggle)
                        }
                        .padding(4)
                    }
                }
                .padding(20)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            ensurePrefsExists()
        }
    }

    private func shortcutRow(_ title: String, name: KeyboardShortcuts.Name) -> some View {
        LabeledContent(title) {
            KeyboardShortcuts.Recorder(for: name)
                .frame(width: 220)
        }
    }

    private func ensurePrefsExists() {
        guard prefsArray.isEmpty else { return }
        context.insert(PrefsModel())
        try? context.save()
    }
}
