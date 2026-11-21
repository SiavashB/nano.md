nonisolated final class RubyHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["rb", "ruby"] }

    private static let rubyBraces = Interpolation(prefix: "#{", opening: "{", closing: "}")

    override func languageToken(depth: Int) -> Kind? {
        if take("#") { return lineComment() }
        let start = remaining.startIndex
        if start == source.startIndex || source[source.index(before: start)].isNewline {
            if rubyCommentMarker("=begin") {
                _ = lineComment()
                while !remaining.isEmpty {
                    remaining.removeFirst()
                    if rubyCommentMarker("=end") { return lineComment() }
                    _ = lineComment()
                }
                return .comment
            }
        }
        if take("\"") {
            return quoted(until: "\"", multiline: true, interpolations: [Self.rubyBraces], depth: depth)
        }
        if take("'") { return quoted(until: "'", multiline: true) }
        if take("`") {
            return quoted(until: "`", multiline: true, interpolations: [Self.rubyBraces], depth: depth)
        }
        return rubyPercentLiteral(depth: depth)
    }

    private func rubyCommentMarker(_ marker: String) -> Bool {
        remaining.hasPrefix(marker) && remaining.dropFirst(marker.count).first?.isWhitespace != false
    }

    private func rubyPercentLiteral(depth: Int) -> Kind? {
        guard remaining.first == "%", let mode = remaining.dropFirst().first,
              "qQwWiIrxs".contains(mode),
              let delimiter = remaining.dropFirst(2).first, !delimiter.isWhitespace,
              !Self.isIdentifierCharacter(delimiter) else { return nil }
        remaining = remaining.dropFirst(3)
        let paired: Character? = switch delimiter {
        case "(": ")"
        case "[": "]"
        case "{": "}"
        case "<": ">"
        default: nil
        }
        let interpolated = "QWIrx".contains(mode)
        return quoted(until: String(paired ?? delimiter), multiline: true,
                      nestedOpener: paired == nil ? nil : delimiter,
                      interpolations: interpolated ? [Self.rubyBraces] : [], depth: depth)
    }
}
