nonisolated final class PythonHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["py", "python", "python3"] }

    override func languageToken(depth: Int) -> Kind? {
        if take("#") { return lineComment() }
        let prefix = remaining.prefix(2).prefix(while: { "fFtTrRuUbB".contains($0) })
        let opener = remaining[prefix.endIndex...]
        guard let first = opener.first, first == "'" || first == "\"" else { return nil }
        let normalized = prefix.lowercased()
        switch normalized {
        case "", "f", "fr", "rf", "t", "tr", "rt", "r", "u", "b", "br", "rb": break
        default: return nil
        }
        let multiline = opener.starts(with: repeatElement(first, count: 3))
        let delimiter = String(repeating: String(first), count: multiline ? 3 : 1)
        remaining = opener.dropFirst(delimiter.count)
        let interpolated = normalized.contains("f") || normalized.contains("t")
        return quoted(until: delimiter, multiline: multiline,
                      interpolations: interpolated ? [Self.doubledBraces] : [], depth: depth)
    }
}
