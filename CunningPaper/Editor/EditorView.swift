import SwiftUI

enum EditorTab: Hashable {
    case cards
    case preferences
    case position

    var label: String {
        switch self {
        case .cards: "Cards"
        case .preferences: "Style"
        case .position: "Position"
        }
    }
}

struct EditorView: View {
    @State private var selectedTab: EditorTab = .cards
    @State private var selectedCardID: UUID?
    @Namespace private var tabNamespace

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                tabButton(.cards, image: "rectangle.split.3x1")
                tabButton(.preferences, image: "slider.horizontal.3")
                tabButton(.position, image: "mappin.and.ellipse")
                Spacer()
            }
            .padding(.horizontal, 4)
            .frame(height: 52)
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
            withAnimation(.spring(duration: 0.3)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: image)
                    .symbolEffect(.bounce, value: selectedTab == tab)
                    .symbolVariant(selectedTab == tab ? .fill : .none)
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(width: 56, height: 44)
            .contentShape(Rectangle())
            .foregroundStyle(selectedTab == tab ? .primary : .tertiary)
            .background {
                if selectedTab == tab {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.primary.opacity(0.1))
                        .matchedGeometryEffect(id: "tabIndicator", in: tabNamespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
