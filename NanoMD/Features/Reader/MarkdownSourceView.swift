import AppKit
import SwiftUI

struct MarkdownSourceView: NSViewRepresentable {
    let source: String
    let theme: AppTheme
    let navigation: DocumentNavigation
    let onEdit: (EditorEntryPoint) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = DocumentScrollView(navigation: navigation)

        let textView = ReaderInteractionTextView(usingTextLayoutManager: true)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = theme.secondary
        textView.textContainerInset = NSSize(width: 20, height: 20)
        NativeTextViewConfiguration.apply(to: textView, in: scrollView)
        textView.setAccessibilityLabel(String(localized: "Markdown source"))
        textView.setAccessibilityHelp(String(localized: "Read-only Markdown source. Select text to copy it."))
        textView.string = source
        textView.sourceSnapshot = source
        textView.displaysSource = true
        textView.onEdit = onEdit
        textView.enableForceClick()
        navigation.reader = textView

        scrollView.documentView = textView
        theme.apply(to: scrollView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        theme.apply(to: scrollView)
        guard let textView = scrollView.documentView as? ReaderInteractionTextView else { return }
        textView.textColor = theme.secondary
        textView.sourceSnapshot = source
        textView.onEdit = onEdit
        navigation.reader = textView
        // Canonically equivalent strings can still contain different source bytes.
        guard !textView.string.utf8.elementsEqual(source.utf8) else {
            return
        }

        textView.string = source
    }
}
