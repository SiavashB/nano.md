import AppKit
import SwiftUI

struct MarkdownEditorView: NSViewRepresentable {
    @Binding var document: NanoMDDocument
    let isActive: Bool
    let theme: AppTheme
    @Environment(\.undoManager) private var undoManager

    func makeCoordinator() -> Coordinator {
        Coordinator(document: $document)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = SourceTextView(usingTextLayoutManager: true)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 0
        textView.setAccessibilityLabel(String(localized: "Markdown source editor"))
        textView.string = document.source
        textView.lineEnding = document.lineEnding
        textView.compositionDidEnd = { [weak coordinator = context.coordinator, weak textView] in
            // Let the input method finish its native edit before applying an accepted reload.
            Task { @MainActor in
                guard let textView else { return }
                coordinator?.applyReload(to: textView)
                textView.applyTextTheme()
            }
        }
        scrollView.documentView = textView
        theme.apply(to: scrollView)
        textView.theme = theme
        textView.applyTextTheme()
        context.coordinator.undoManager = undoManager
        scrollView.isHidden = !isActive
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SourceTextView else { return }
        let coordinator = context.coordinator
        coordinator.document = $document
        coordinator.undoManager = undoManager
        coordinator.applyReload(to: textView)
        theme.apply(to: scrollView)
        textView.theme = theme
        textView.applyTextTheme()

        if !isActive, scrollView.window?.firstResponder === textView {
            textView.breakUndoCoalescing()
            scrollView.window?.makeFirstResponder(nil)
        }
        scrollView.isHidden = !isActive
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        // The manager is document-scoped; its native text targets must not outlive the window.
        coordinator.undoManager?.removeAllActions()
        (scrollView.documentView as? NSTextView)?.delegate = nil
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var document: Binding<NanoMDDocument>
        weak var undoManager: UndoManager?
        private var loadIdentity: UUID
        private var isApplyingReload = false

        init(document: Binding<NanoMDDocument>) {
            self.document = document
            loadIdentity = document.wrappedValue.loadIdentity
        }

        func undoManager(for view: NSTextView) -> UndoManager? {
            undoManager
        }

        func applyReload(to textView: SourceTextView) {
            let value = document.wrappedValue
            guard value.loadIdentity != loadIdentity else { return }
            guard !textView.hasMarkedText() else { return }

            isApplyingReload = true
            defer { isApplyingReload = false }
            textView.breakUndoCoalescing()
            undoManager?.removeAllActions()
            loadIdentity = value.loadIdentity
            textView.lineEnding = value.lineEnding
            if !textView.string.utf8.elementsEqual(value.source.utf8) {
                textView.string = value.source
            }
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingReload, let textView = notification.object as? SourceTextView else { return }
            textView.applyTextTheme()
            // The system owns conflict acceptance. Never publish an old editor over its reload.
            guard document.wrappedValue.loadIdentity == loadIdentity else {
                applyReload(to: textView)
                return
            }
            guard !document.wrappedValue.source.utf8.elementsEqual(textView.string.utf8) else { return }

            // NSTextView owns typing undo. Suppress FileDocument binding undo for this publication
            // so a second whole-document action cannot accompany the native text operation.
            undoManager?.disableUndoRegistration()
            defer { undoManager?.enableUndoRegistration() }
            document.wrappedValue.source = textView.string
        }
    }

    final class SourceTextView: NSTextView {
        var lineEnding = "\n"
        var compositionDidEnd: (() -> Void)?
        var theme: AppTheme = .linenLight
        private var appliedTextTheme: AppTheme?

        func applyTextTheme() {
            // Leave marked text under input-method ownership until composition finishes.
            guard !hasMarkedText(), appliedTextTheme != theme else { return }
            textColor = theme.secondary
            typingAttributes[.foregroundColor] = theme.secondary
            appliedTextTheme = theme
        }

        override func insertNewline(_ sender: Any?) {
            insertText(lineEnding, replacementRange: NSRange(location: NSNotFound, length: 0))
        }

        override func insertLineBreak(_ sender: Any?) {
            insertNewline(sender)
        }

        override func unmarkText() {
            super.unmarkText()
            compositionDidEnd?()
        }

        override func paste(_ sender: Any?) {
            pasteAsPlainText(sender)
        }
    }
}
