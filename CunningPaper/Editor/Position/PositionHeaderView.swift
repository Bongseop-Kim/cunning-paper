import SwiftUI

struct PositionHeaderView: View {
    let monitors: [MonitorInfo]
    let selectedMonitorIndex: Int
    let onMonitorSelect: (Int) -> Void
    let monitor: MonitorInfo?
    let summary: String

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Display Position")
                    .font(.title2.weight(.semibold))

                Text("Choose where the overlay appears on each monitor.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 24)

            VStack(alignment: .trailing, spacing: 8) {
                if monitors.count > 1 {
                    Picker("Display", selection: Binding(
                        get: { selectedMonitorIndex },
                        set: onMonitorSelect
                    )) {
                        ForEach(Array(monitors.enumerated()), id: \.offset) { index, monitor in
                            Text(monitor.name).tag(index)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                } else {
                    Text(monitor?.name ?? "No display")
                        .font(.headline)
                }

                Text(monitor.map { "\($0.width) × \($0.height) • \($0.orientationLabel)" } ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summary)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.quaternary.opacity(0.6), in: Capsule())
            }
        }
    }
}
