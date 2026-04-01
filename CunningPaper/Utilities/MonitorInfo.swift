import AppKit

struct MonitorInfo: Identifiable, Equatable {
    let name: String
    let width: Int
    let height: Int
    let x: Int
    let y: Int
    let scaleFactor: Double

    var id: String {
        "\(x):\(y):\(width):\(height):\(scaleFactor)"
    }

    var isVertical: Bool {
        height > width
    }

    var orientationLabel: String {
        isVertical ? "Vertical" : "Horizontal"
    }

    static func all() -> [MonitorInfo] {
        let screens = NSScreen.screens
        if screens.isEmpty {
            return [
                MonitorInfo(name: "Built-in", width: 1920, height: 1080, x: 0, y: 0, scaleFactor: 2),
            ]
        }
        return screens.map { screen in
            let frame = screen.frame
            return MonitorInfo(
                name: screen.localizedName,
                width: Int(frame.width),
                height: Int(frame.height),
                x: Int(frame.origin.x),
                y: Int(frame.origin.y),
                scaleFactor: screen.backingScaleFactor
            )
        }
    }
}

struct DisplayRect: Equatable {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
}

struct PhysicalBounds: Equatable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
