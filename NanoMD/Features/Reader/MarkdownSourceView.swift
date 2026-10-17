import AppKit
import SwiftUI

struct MarkdownSourceView: NSViewRepresentable {
    let source: String
    let theme: AppTheme

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView(usingTextLayoutManager: true)
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
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 0
        textView.setAccessibilityLabel(String(localized: "Markdown source"))
        textView.setAccessibilityHelp(String(localized: "Read-only Markdown source. Select text to copy it."))
        textView.string = source

        scrollView.documentView = textView
        theme.apply(to: scrollView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        theme.apply(to: scrollView)
        (scrollView.documentView as? NSTextView)?.textColor = theme.secondary
        // Canonically equivalent strings can still contain different source bytes.
        guard let textView = scrollView.documentView as? NSTextView,
              !textView.string.utf8.elementsEqual(source.utf8) else {
            return
        }

        textView.string = source
    }
}
