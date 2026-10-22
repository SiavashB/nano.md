import Foundation
import Markdown

/// Source coordinates use UTF-16 to match native text selection, never rendered offsets.
nonisolated struct MarkdownSourceSpan: Sendable {
    let range: Range<Int>
    let text: String
}

nonisolated struct MarkdownSourceIndex {
    private let source: String
    private let lineStarts: [String.UTF8View.Index]
    private let lineOffsets: [Int]
    private let baseOffset: Int

    init(_ source: String, baseOffset: Int = 0) {
        self.source = source
        self.baseOffset = baseOffset
        var starts = [source.utf8.startIndex]
        var offsets = [0]
        var utf16Offset = 0
        var index = source.utf8.startIndex
        while index < source.utf8.endIndex {
            let byte = source.utf8[index]
            source.utf8.formIndex(after: &index)
            if byte < 0x80 || byte >= 0xC0 { utf16Offset += byte >= 0xF0 ? 2 : 1 }
            if byte == 13 {
                if index < source.utf8.endIndex, source.utf8[index] == 10 {
                    source.utf8.formIndex(after: &index)
                    utf16Offset += 1
                }
                starts.append(index)
                offsets.append(utf16Offset)
            } else if byte == 10 {
                starts.append(index)
                offsets.append(utf16Offset)
            }
        }
        lineStarts = starts
        lineOffsets = offsets
    }

    func span(for node: any Markup) -> MarkdownSourceSpan? {
        guard let range = node.range,
              let start = position(at: range.lowerBound),
              let end = position(at: range.upperBound), start.index <= end.index else { return nil }
        return MarkdownSourceSpan(range: start.offset..<end.offset, text: String(source[start.index..<end.index]))
    }

    func contentSpan(for node: any Markup) -> MarkdownSourceSpan? {
        guard let span = span(for: node) else { return nil }
        let raw = span.text as NSString
        var range = NSRange(location: 0, length: raw.length)
        if node is InlineCode {
            let ticks = span.text.prefix(while: { $0 == "`" }).count
            if ticks > 0, raw.length >= ticks * 2 {
                range = NSRange(location: ticks, length: raw.length - ticks * 2)
            }
        } else if node is CodeBlock, let fence = span.text.first, fence == "`" || fence == "~" {
            let count = span.text.prefix(while: { $0 == fence }).count
            if count >= 3 {
                let firstLine = raw.lineRange(for: NSRange(location: 0, length: 0))
                range = NSRange(location: NSMaxRange(firstLine), length: raw.length - NSMaxRange(firstLine))
                if range.length > 0 {
                    let lastLine = raw.lineRange(for: NSRange(location: raw.length - 1, length: 0))
                    let closing = raw.substring(with: lastLine).trimmingCharacters(in: .whitespacesAndNewlines)
                    let prefix = closing.drop(while: { $0 == ">" || $0.isWhitespace })
                    if prefix.count >= count, prefix.allSatisfy({ $0 == fence }) {
                        range.length = max(0, lastLine.location - range.location)
                    }
                }
            }
        }
        let lower = span.range.lowerBound + range.location
        return MarkdownSourceSpan(range: lower..<(lower + range.length), text: raw.substring(with: range))
    }

    private func position(at location: SourceLocation) -> (index: String.Index, offset: Int)? {
        guard location.line > 0, location.line <= lineStarts.count, location.column > 0 else { return nil }
        let start = lineStarts[location.line - 1]
        let limit = location.line < lineStarts.count ? lineStarts[location.line] : source.utf8.endIndex
        guard let index = source.utf8.index(start, offsetBy: location.column - 1, limitedBy: limit) else {
            return nil
        }
        guard let stringIndex = String.Index(index, within: source) else { return nil }
        let offset = lineOffsets[location.line - 1] + source[start..<stringIndex].utf16.count + baseOffset
        return (stringIndex, offset)
    }
}
