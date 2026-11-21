nonisolated final class JavaHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["java"] }

    override func languageToken(depth: Int) -> Kind? {
        if let comment = slashComment() { return comment }
        if take("\"\"\"") { return quoted(until: "\"\"\"", multiline: true) }
        return simpleQuote()
    }
}
