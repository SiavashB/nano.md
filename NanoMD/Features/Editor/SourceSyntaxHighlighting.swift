import AppKit

/// Supplies styled paragraphs to TextKit while leaving the editor's backing text plain.
@MainActor
final class SourceSyntaxHighlighting: NSObject, NSTextContentStorageDelegate {
    let language: String
    private weak var textView: NSTextView?
    private var colors: CodeHighlightColors
    private var highlights: [MarkdownCodeBlock.Highlight] = []
    private var validPrefixEnd = 0
    private var scan: Task<Void, Never>?

    init?(textView: NSTextView, language: String, theme: AppTheme) {
        guard let content = textView.textContentStorage, let storage = content.textStorage else { return nil }
        self.textView = textView
        self.language = language
        colors = CodeHighlightColors(theme)
        super.init()
        content.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(charactersEdited(_:)),
                                               name: NSTextStorage.didProcessEditingNotification, object: storage)
        refresh()
    }

    @objc private func charactersEdited(_ notification: Notification) {
        guard let storage = notification.object as? NSTextStorage,
              storage.editedMask.contains(.editedCharacters) else { return }
        // Positions before the edit still match, including earlier tokens on the line being typed.
        validPrefixEnd = min(validPrefixEnd, storage.editedRange.location)
        refresh(afterTyping: true)
    }

    func refresh(afterTyping: Bool = false) {
        scan?.cancel()
        guard textView?.hasMarkedText() == false else { return }
        let language = self.language
        scan = Task { [weak self] in
            if afterTyping {
                do { try await Task.sleep(for: .milliseconds(120)) } catch { return }
            }
            guard !Task.isCancelled, let source = self?.textView?.string else { return }
            let result = await CodeBlockHighlighter.fileHighlights(in: source, language: language)
            guard !Task.isCancelled, let self, self.textView?.hasMarkedText() == false else { return }
            guard !result.isEmpty || !self.highlights.isEmpty else { return }
            self.highlights = result
            self.validPrefixEnd = Int.max
            self.invalidate()
        }
    }

    func applyTheme(_ theme: AppTheme) {
        colors = CodeHighlightColors(theme)
        invalidate()
    }

    func detach() {
        scan?.cancel()
        NotificationCenter.default.removeObserver(self)
        guard let content = textView?.textContentStorage, content.delegate === self else { return }
        content.delegate = nil
        invalidate()
    }

    private func invalidate() {
        guard let textView, let storage = textView.textContentStorage?.textStorage, storage.length > 0 else { return }
        storage.edited(.editedAttributes, range: NSRange(location: 0, length: storage.length), changeInLength: 0)
        // The initial viewport can already contain plain paragraphs when the background scan finishes.
        // Rebuild its visible fragments now, even if the window and the selection stay idle.
        if textView.window != nil {
            textView.textLayoutManager?.textViewportLayoutController.layoutViewport()
        }
        textView.needsDisplay = true
    }

    func textContentStorage(_ content: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        guard !highlights.isEmpty, textView?.hasMarkedText() == false,
              let storage = content.textStorage, NSMaxRange(range) <= storage.length else { return nil }
        let start = range.location
        let end = min(validPrefixEnd, NSMaxRange(range))
        guard start < end else { return nil }

        // The scanner emits ordered UTF-16 ranges. Seek to the first token crossing this paragraph.
        var low = 0
        var high = highlights.count
        while low < high {
            let middle = low + (high - low) / 2
            if NSMaxRange(highlights[middle].range) <= start {
                low = middle + 1
            } else {
                high = middle
            }
        }
        guard low < highlights.count, highlights[low].range.location < end else { return nil }
        let text = NSMutableAttributedString(attributedString: storage.attributedSubstring(from: range))
        for token in highlights[low...] {
            if token.range.location >= end { break }
            let lower = max(token.range.location, start) - start
            let upper = min(NSMaxRange(token.range), end) - start
            text.addAttribute(.foregroundColor, value: colors[token.kind],
                              range: NSRange(location: lower, length: upper - lower))
        }
        return NSTextParagraph(attributedString: text)
    }
}
