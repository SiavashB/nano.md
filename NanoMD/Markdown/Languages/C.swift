nonisolated class CHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["c"] }

    override func languageToken(depth: Int) -> Kind? {
        if let comment = slashComment(continuedLines: true) { return comment }
        if let quote = simpleQuote() { return quote }
        if let first = remaining.first, ("0"..."9").contains(first) {
            remaining = remaining.drop(while: Self.isIdentifierCharacter)
            while remaining.first == "'", let next = remaining.dropFirst().first,
                  Self.isIdentifierCharacter(next) {
                remaining = remaining.dropFirst().drop(while: Self.isIdentifierCharacter)
            }
        }
        return nil
    }
}
