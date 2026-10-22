import AppKit

extension NSAttributedString.Key {
    static let markdownSourceMapping = Self("NanoMD.sourceMapping")
    static let markdownSourceAnchor = Self("NanoMD.sourceAnchor")
}

/// A rendered run stays tied to its parser span, including repeated text elsewhere in the file.
final class ReaderSourceMapping: NSObject {
    private let span: MarkdownSourceSpan
    private let rendered: String
    private let renderedStart: Int

    init(span: MarkdownSourceSpan, rendered: String, renderedStart: Int) {
        self.span = span
        self.rendered = rendered
        self.renderedStart = renderedStart
    }

    func sourceOffset(at renderedOffset: Int) -> Int {
        let target = min(max(0, renderedOffset - renderedStart), rendered.utf16.count)
        let source = Array(span.text.utf16)
        let display = Array(rendered.utf16)
        var prefix = 0
        while prefix < min(source.count, display.count), source[prefix] == display[prefix] {
            prefix += 1
        }
        if target < prefix { return span.range.lowerBound + target }
        var suffix = 0
        while suffix < min(source.count, display.count) - prefix,
              source[source.count - suffix - 1] == display[display.count - suffix - 1] {
            suffix += 1
        }
        if target >= display.count - suffix {
            return span.range.lowerBound + source.count - (display.count - target)
        }

        let original = Array(source[prefix..<(source.count - suffix)])
        let visible = Array(display[prefix..<(display.count - suffix)])
        // Bound the diff for unusually large transformed leaves; ordinary long text uses
        // the exact prefix/suffix path. Large code blocks can still be matched line by line.
        guard original.count + visible.count <= 8_192 else {
            return sourceOffsetInLines(at: target)
        }
        let changes = visible.difference(from: original)
        var removed = Set<Int>()
        var inserted = Set<Int>()
        for change in changes {
            switch change {
            case let .remove(offset, _, _): removed.insert(offset)
            case let .insert(offset, _, _): inserted.insert(offset)
            }
        }
        var sourceIndex = 0
        for index in 0...(target - prefix) {
            if !inserted.contains(index) {
                while removed.contains(sourceIndex) { sourceIndex += 1 }
            }
            if index == target - prefix {
                return span.range.lowerBound + prefix + min(sourceIndex, original.count)
            }
            if !inserted.contains(index) { sourceIndex += 1 }
        }
        return span.range.lowerBound
    }

    private func sourceOffsetInLines(at target: Int) -> Int {
        let original = span.text as NSString
        let display = rendered as NSString
        var displayStart = 0
        var sourceStart = 0
        while displayStart < display.length {
            let lineRange = display.lineRange(for: NSRange(location: displayStart, length: 0))
            let line = display.substring(with: lineRange).trimmingCharacters(in: .newlines)
            let match = original.range(of: line, options: .literal,
                                       range: NSRange(location: sourceStart, length: original.length - sourceStart))
            if match.location != NSNotFound {
                if NSMaxRange(lineRange) > target {
                    return span.range.lowerBound + match.location + min(target - displayStart, match.length)
                }
                sourceStart = NSMaxRange(original.lineRange(for: match))
            } else if NSMaxRange(lineRange) > target {
                return span.range.lowerBound + sourceStart
            }
            displayStart = NSMaxRange(lineRange)
        }
        return span.range.upperBound
    }
}
