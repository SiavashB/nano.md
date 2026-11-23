import Foundation

nonisolated final class HTMLHighlighter: MarkupHighlighter {
    override class var fenceTags: [String] { ["html", "htm"] }

    private static let textElements: Set<String> = [
        "script", "style", "textarea", "title", "iframe", "noembed", "noframes", "xmp"
    ]
    private static let javaScriptTypes: Set<String> = [
        "", "module", "application/javascript", "application/ecmascript", "text/javascript", "text/ecmascript",
        "application/x-javascript", "application/x-ecmascript", "text/x-javascript", "text/x-ecmascript",
        "text/javascript1.0", "text/javascript1.1", "text/javascript1.2", "text/javascript1.3",
        "text/javascript1.4", "text/javascript1.5", "text/jscript", "text/livescript"
    ]

    override func scanTagBody(named name: Substring, closing: Bool) {
        let tag = name.lowercased()
        guard !closing, Self.textElements.contains(tag) else {
            scanAttributes(allowUnquotedValues: true)
            return
        }
        var scriptType: Substring?
        let complete = scanAttributes(allowUnquotedValues: true) { attribute, value in
            if tag == "script", scriptType == nil, attribute.lowercased() == "type" { scriptType = value }
        }
        guard complete else { return }

        let end = startOfClosingTag(tag)
        let type = (scriptType ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if tag == "script", Self.javaScriptTypes.contains(type) {
            // Give JavaScript the bounded slice so an unfinished string cannot consume the closing tag.
            let script = JavaScriptHighlighter(source)
            script.remaining = remaining[..<end]
            while !script.remaining.isEmpty {
                let kind = script.advance(depth: 0)
                consume(to: script.remaining.startIndex, as: kind)
            }
        } else {
            if tag == "title" || tag == "textarea" {
                while let reference = remaining[..<end].firstIndex(of: "&") {
                    consume(to: reference)
                    scanReference()
                }
            }
            consume(to: end)
        }
    }

    private func startOfClosingTag(_ tag: String) -> String.Index {
        let closing = "</" + tag
        var search = remaining
        while let start = search.firstIndex(of: "<") {
            let candidate = search[start...].prefix(closing.count)
            if candidate.lowercased() == closing, let next = search[candidate.endIndex...].first,
               Self.isMarkupSpace(next) || next == ">" || next == "/" {
                return start
            }
            search = search[search.index(after: start)...]
        }
        return remaining.endIndex
    }
}
