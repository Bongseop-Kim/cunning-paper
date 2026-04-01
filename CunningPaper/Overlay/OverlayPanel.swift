import AppKit
import SwiftData
import SwiftUI

final class OverlayPanel: NSPanel {
    init(modelContainer: ModelContainer) {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 520, height: 180),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        ignoresMouseEvents = true
        hasShadow = false
        animationBehavior = .utilityWindow

        let rootView = OverlayView()
            .modelContainer(modelContainer)
        contentView = NSHostingView(rootView: rootView)
    }

    func fadeIn() {
        guard !isVisible else { return }
        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 1
        }
    }

    func fadeOut() {
        guard isVisible else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
            self?.alphaValue = 1
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
