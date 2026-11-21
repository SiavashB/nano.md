nonisolated final class CSharpHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["c#", "cs", "csharp"] }

    override func languageToken(depth: Int) -> Kind? {
        if let comment = slashComment() { return comment }
        if take("$@\"") || take("@$\"") {
            return quoted(until: "\"", multiline: true, escape: nil, doubledDelimiter: true,
                          interpolations: [Self.doubledBraces], depth: depth)
        }
        if take("@\"") {
            return quoted(until: "\"", multiline: true, escape: nil, doubledDelimiter: true)
        }
        let dollars = remaining.prefix(while: { $0 == "$" })
        let opener = remaining[dollars.endIndex...]
        if opener.hasPrefix("\"\"\"") {
            let quotes = opener.prefix(while: { $0 == "\"" })
            let width = quotes.count
            remaining = opener[quotes.endIndex...]
            while !remaining.isEmpty {
                remaining = remaining.drop(while: { $0 != "\"" })
                let closing = remaining.prefix(while: { $0 == "\"" })
                remaining = remaining[closing.endIndex...]
                if closing.count >= width { break }
            }
            return .quotedText
        }
        if take("$\"") {
            return quoted(until: "\"", interpolations: [Self.doubledBraces], depth: depth)
        }
        return simpleQuote()
    }
}
