import AppKit
import SwiftUI

struct MarkdownTextView: NSViewRepresentable {
    let text: NSAttributedString
    let theme: AppTheme

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        // Native text tables use the TextKit 1 layout path.
        let textView = ReaderTextView(usingTextLayoutManager: false)
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.textContainerInset = NSSize(width: 28, height: 24)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 0
        textView.setAccessibilityLabel(String(localized: "Markdown document"))
        textView.textStorage?.setAttributedString(text)
        context.coordinator.displayedText = text
        scrollView.documentView = textView
        theme.apply(to: scrollView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        theme.apply(to: scrollView)
        guard context.coordinator.displayedText !== text,
              let textView = scrollView.documentView as? NSTextView else { return }
        let retainsPosition = textView.string.utf8.elementsEqual(text.string.utf8)
        let selection = textView.selectedRanges
        let origin = scrollView.contentView.bounds.origin
        textView.textStorage?.setAttributedString(text)
        if retainsPosition {
            textView.selectedRanges = selection
            if let container = textView.textContainer {
                textView.layoutManager?.ensureLayout(for: container)
            }
            scrollView.contentView.scroll(to: origin)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
        context.coordinator.displayedText = text
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var displayedText: NSAttributedString?

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            let destination = (link as? URL)?.absoluteString ?? (link as? String)
            if let destination, let url = ReaderLinkPolicy.allowedURL(destination) {
                NSWorkspace.shared.open(url)
            }
            // Always consume the event so AppKit cannot open a rejected URL itself.
            return true
        }
    }
}

private final class ReaderTextView: NSTextView {
    override func draw(_ dirtyRect: NSRect) {
        // Table borders need final row geometry before their backgrounds are drawn.
        if let textContainer {
            layoutManager?.ensureLayout(for: textContainer)
        }
        super.draw(dirtyRect)
    }
}
