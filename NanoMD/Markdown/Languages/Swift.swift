nonisolated final class SwiftHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["swift"] }

    override func languageToken(depth: Int) -> Kind? {
        if let comment = slashComment(nested: true) { return comment }
        if take("`") { return quoted(until: "`", escape: nil) }
        let hashes = remaining.prefix(while: { $0 == "#" })
        let opener = remaining[hashes.endIndex...]
        guard opener.first == "\"" else {
            if !hashes.isEmpty { remaining = opener }
            return nil
        }
        let multiline = opener.hasPrefix("\"\"\"")
        let delimiter = multiline ? "\"\"\"" : "\""
        remaining = opener.dropFirst(delimiter.count)
        let escape = "\\" + hashes
        let interpolation = Interpolation(prefix: escape + "(", opening: "(", closing: ")")
        return quoted(until: delimiter + hashes, multiline: multiline, escape: escape,
                      interpolations: [interpolation], depth: depth)
    }
}
