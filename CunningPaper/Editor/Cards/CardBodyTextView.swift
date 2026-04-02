import AppKit
import SwiftUI

struct CardBodyTextView: NSViewRepresentable {
    @Binding var text: String
    let documentID: UUID
    var onActiveParagraphChange: (Int?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, documentID: documentID, onActiveParagraphChange: onActiveParagraphChange)
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

        if context.coordinator.lastSeenDocumentID != documentID {
            context.coordinator.resetForDocumentChange(to: documentID, text: text, in: textView)
            return
        }

        // Do not touch the backing string or selection while an IME composition is active.
        guard !textView.hasMarkedText() else { return }

        if textView.string != text {
            let selectedRange = Self.synchronizedSelectionRange(
                currentText: textView.string,
                newText: text,
                currentSelection: textView.selectedRange()
            )
            textView.string = text
            textView.setSelectedRange(selectedRange)
        }

        DispatchQueue.main.async {
            context.coordinator.reportSelection(for: textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        private(set) var lastSeenDocumentID: UUID
        var onActiveParagraphChange: (Int?) -> Void
        private var lastReportedParagraphIndex: Int?

        init(text: Binding<String>, documentID: UUID, onActiveParagraphChange: @escaping (Int?) -> Void) {
            _text = text
            lastSeenDocumentID = documentID
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

        func resetForDocumentChange(to documentID: UUID, text: String, in textView: NSTextView) {
            lastSeenDocumentID = documentID
            textView.string = text
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            let index = ParagraphFocus.activeParagraphIndex(
                in: textView.string,
                selectedRange: textView.selectedRange()
            )
            lastReportedParagraphIndex = index
            onActiveParagraphChange(index)
        }
    }

    static func synchronizedSelectionRange(
        currentText: String,
        newText: String,
        currentSelection: NSRange
    ) -> NSRange {
        let newRange = NSRange(location: 0, length: (newText as NSString).length)
        guard shouldPreserveSelection(currentText: currentText, newText: newText) else {
            return NSRange(location: 0, length: 0)
        }

        return NSIntersectionRange(currentSelection, newRange)
    }

    private static func shouldPreserveSelection(currentText: String, newText: String) -> Bool {
        guard !currentText.isEmpty, !newText.isEmpty else { return false }

        return newText.hasPrefix(currentText)
            || newText.hasSuffix(currentText)
            || currentText.hasPrefix(newText)
            || currentText.hasSuffix(newText)
    }
}
