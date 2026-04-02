import Foundation

enum ZonePickerMath {
    static let minimapDisplayWidth: CGFloat = 420
    static let minimapMaxDisplayHeight: CGFloat = 520

    static func minimapScale(monitor: MonitorInfo, displayWidth: CGFloat = minimapDisplayWidth) -> CGFloat {
        displayWidth / max(CGFloat(monitor.width), 1)
    }

    static func placementCanvasSize(
        monitor: MonitorInfo,
        maxWidth: CGFloat = minimapDisplayWidth,
        maxHeight: CGFloat = minimapMaxDisplayHeight
    ) -> (width: CGFloat, height: CGFloat, scale: CGFloat) {
        let scale = min(maxWidth / CGFloat(max(monitor.width, 1)), maxHeight / CGFloat(max(monitor.height, 1)))
        return (
            width: max((CGFloat(monitor.width) * scale).rounded(), 1),
            height: max((CGFloat(monitor.height) * scale).rounded(), 1),
            scale: scale
        )
    }

    static func displayRectToPhysicalBounds(
        rect: DisplayRect,
        monitor: MonitorInfo,
        canvasWidth: CGFloat
    ) -> PhysicalBounds {
        let scale = minimapScale(monitor: monitor, displayWidth: canvasWidth)
        let physicalHeight = (rect.h / scale).rounded()
        return PhysicalBounds(
            x: (rect.x / scale + CGFloat(monitor.x)).rounded(),
            y: (CGFloat(monitor.y) + CGFloat(monitor.height) - ((rect.y + rect.h) / scale)).rounded(),
            width: (rect.w / scale).rounded(),
            height: physicalHeight
        )
    }

    static func physicalBoundsToDisplayRect(
        bounds: PhysicalBounds,
        monitor: MonitorInfo,
        canvasWidth: CGFloat
    ) -> DisplayRect {
        let scale = minimapScale(monitor: monitor, displayWidth: canvasWidth)
        return DisplayRect(
            x: ((bounds.x - CGFloat(monitor.x)) * scale).rounded(),
            y: ((CGFloat(monitor.height) - (bounds.y - CGFloat(monitor.y)) - bounds.height) * scale).rounded(),
            w: (bounds.width * scale).rounded(),
            h: (bounds.height * scale).rounded()
        )
    }

    static func clamp(rect: DisplayRect, canvasWidth: CGFloat, canvasHeight: CGFloat) -> DisplayRect {
        let clampedX = min(max(rect.x, 0), canvasWidth)
        let clampedY = min(max(rect.y, 0), canvasHeight)
        return DisplayRect(
            x: clampedX,
            y: clampedY,
            w: min(max(rect.w, 0), canvasWidth - clampedX),
            h: min(max(rect.h, 0), canvasHeight - clampedY)
        )
    }
}
