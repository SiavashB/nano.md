nonisolated final class KotlinHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["kt", "kts", "kotlin"] }

    override func languageToken(depth: Int) -> Kind? {
        if let comment = slashComment(nested: true) { return comment }
        if take("`") { return quoted(until: "`", escape: nil) }
        let dollars = remaining.prefix(while: { $0 == "$" })
        let opener = remaining[dollars.endIndex...]
        guard opener.first == "\"" else { return simpleQuote() }
        let multiline = opener.hasPrefix("\"\"\"")
        let delimiter = multiline ? "\"\"\"" : "\""
        remaining = opener.dropFirst(delimiter.count)
        let interpolation = dollars.isEmpty ? Self.dollarBraces : Interpolation(
            prefix: String(dollars) + "{", opening: "{", closing: "}"
        )
        let kind = quoted(until: delimiter, multiline: multiline, escape: multiline ? nil : "\\",
                          interpolations: [interpolation], depth: depth)
        if multiline { remaining = remaining.drop(while: { $0 == "\"" }) }
        return kind
    }
}
