import AppKit
import SwiftUI

struct CardBodyTextView: NSViewRepresentable {
    @Binding var text: String
    var onActiveParagraphChange: (Int?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onActiveParagraphChange: onActiveParagraphChange)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.usesFindBar = true
        textView.drawsBackground = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.string = text

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.onActiveParagraphChange = onActiveParagraphChange

        // Do not touch the backing string or selection while an IME composition is active.
        guard !textView.hasMarkedText() else { return }

        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(NSIntersectionRange(selectedRange, NSRange(location: 0, length: (text as NSString).length)))
        }

        DispatchQueue.main.async {
            context.coordinator.reportSelection(for: textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var onActiveParagraphChange: (Int?) -> Void
        private var lastReportedParagraphIndex: Int?

        init(text: Binding<String>, onActiveParagraphChange: @escaping (Int?) -> Void) {
            _text = text
            self.onActiveParagraphChange = onActiveParagraphChange
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            if !textView.hasMarkedText() {
                reportSelection(for: textView)
            }
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if !textView.hasMarkedText() {
                reportSelection(for: textView)
            }
        }

        func reportSelection(for textView: NSTextView) {
            let index = ParagraphFocus.activeParagraphIndex(
                in: textView.string,
                selectedRange: textView.selectedRange()
            )
            guard index != lastReportedParagraphIndex else { return }
            lastReportedParagraphIndex = index

            DispatchQueue.main.async { [weak self] in
                self?.onActiveParagraphChange(index)
            }
        }
    }
}
