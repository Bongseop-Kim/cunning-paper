import SwiftUI

enum EditorTab: Hashable {
    case cards
    case preferences
    case position
}

struct EditorView: View {
    @State private var selectedTab: EditorTab = .cards
    @State private var selectedCardID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tabButton(.cards, image: "rectangle.split.3x1")
                tabButton(.preferences, image: "slider.horizontal.3")
                tabButton(.position, image: "mappin.and.ellipse")
                Spacer()
            }
            .frame(height: 38)
            .background(.bar)
            .overlay(alignment: .bottom) { Divider() }

            Group {
                switch selectedTab {
                case .cards:
                    CardStudioView(selectedCardID: $selectedCardID)
                case .preferences:
                    PreferencesView()
                case .position:
                    ZonePickerView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func tabButton(_ tab: EditorTab, image: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Image(systemName: image)
                .frame(width: 40, height: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
    }
}
