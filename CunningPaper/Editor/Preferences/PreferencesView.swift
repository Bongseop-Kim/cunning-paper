import SwiftData
import SwiftUI

struct PreferencesView: View {
    @Environment(\.modelContext) private var context
    @Query private var prefsArray: [PrefsModel]
    @State private var saveErrorMessage: String?

    var body: some View {
        ScrollView {
            if let prefs = prefsArray.first {
                VStack(alignment: .leading, spacing: 32) {
                    header

                    preferenceSection(
                        title: "Appearance",
                        description: "Adjust how the reading overlay feels on screen."
                    ) {
                        VStack(spacing: 0) {
                            sliderRow(
                                title: "Font Size",
                                detail: "Scale the overlay text for comfortable reading.",
                                valueText: "\(Int(prefs.fontSize)) pt",
                                value: Binding(
                                    get: { prefs.fontSize },
                                    set: {
                                        prefs.fontSize = $0
                                        savePreferences()
                                    }
                                ),
                                range: 14...40,
                                step: 1,
                                showDivider: true
                            )

                            sliderRow(
                                title: "Opacity",
                                detail: "Control how strongly the overlay sits over other content.",
                                valueText: "\(Int(prefs.opacity * 100))%",
                                value: Binding(
                                    get: { prefs.opacity },
                                    set: {
                                        prefs.opacity = $0
                                        savePreferences()
                                    }
                                ),
                                range: 0.35...1.0,
                                step: 0.05,
                                showDivider: true
                            )

                            toggleRow(
                                title: "Highlight Current Paragraph",
                                detail: "Keep the active paragraph visually anchored while reading.",
                                isOn: Binding(
                                    get: { prefs.highlightCurrentParagraph },
                                    set: {
                                        prefs.highlightCurrentParagraph = $0
                                        savePreferences()
                                    }
                                ),
                                showDivider: false
                            )
                        }
                    }

                    preferenceSection(
                        title: "Shortcuts",
                        description: "Review and remap the keyboard actions used while presenting cards."
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            shortcutRow("Next Card", name: .next, showDivider: true)
                            shortcutRow("Previous Card", name: .prev, showDivider: true)
                            shortcutRow("Jump", name: .jump, showDivider: true)
                            shortcutRow("Next Paragraph", name: .nextLine, showDivider: true)
                            shortcutRow("Previous Paragraph", name: .prevLine, showDivider: true)
                            shortcutRow("Toggle Overlay", name: .toggle, showDivider: false)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            ensurePrefsExists()
        }
        .alert("Couldn't Save Preferences", isPresented: saveErrorPresented) {
            Button("OK") {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "The preference change could not be saved.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style")
                .font(.system(size: 28, weight: .semibold, design: .rounded))

            Text("Tune the overlay typography and keyboard controls for your reading flow.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    private func preferenceSection<Content: View>(
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.quaternary.opacity(0.7))
            }
        }
    }

    private func sliderRow(
        title: String,
        detail: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        showDivider: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                valueChip(valueText)
            }

            Slider(value: value, in: range, step: step)
                .tint(.accentColor)
                .accessibilityLabel(title)
                .accessibilityValue(valueText)
                .accessibilityHint(detail)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(rowBackground(showDivider: showDivider))
    }

    private func toggleRow(
        title: String,
        detail: String,
        isOn: Binding<Bool>,
        showDivider: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel(title)
                .accessibilityHint(detail)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(rowBackground(showDivider: showDivider))
    }

    private func shortcutRow(
        _ title: String,
        name: KeyboardShortcuts.Name,
        showDivider: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            KeyboardShortcuts.Recorder(for: name)
                .frame(width: 220)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(rowBackground(showDivider: showDivider))
    }

    private func ensurePrefsExists() {
        guard prefsArray.isEmpty else { return }
        context.insert(PrefsModel())
        savePreferences()
    }

    private func savePreferences() {
        do {
            try context.save()
        } catch {
            context.rollback()
            NSLog("Failed to save preferences: %@", error.localizedDescription)
            saveErrorMessage = error.localizedDescription
        }
    }

    private var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    saveErrorMessage = nil
                }
            }
        )
    }

    private func valueChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
    }

    private func rowBackground(showDivider: Bool) -> some View {
        Rectangle()
            .fill(.clear)
            .overlay(alignment: .bottom) {
                if showDivider {
                    Divider()
                        .padding(.leading, 18)
                }
            }
    }
}
