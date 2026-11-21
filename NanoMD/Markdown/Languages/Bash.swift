nonisolated final class BashHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["sh", "shell", "bash", "shellscript"] }

    private static let shellSeparators = Set("|&;()<>")
    private static let shellCommand = Interpolation(prefix: "$(", opening: "(", closing: ")")
    private var shellWordStart = true
    private var shellParameterDepth = 0

    override func advance(depth: Int) -> Kind? {
        guard let first = remaining.first else { return nil }
        let kind = super.advance(depth: depth)
        if first != "\\" || !source[source.index(before: remaining.startIndex)].isNewline {
            shellWordStart = first.isWhitespace || Self.shellSeparators.contains(first)
        }
        return kind
    }

    override func languageToken(depth: Int) -> Kind? {
        if shellWordStart && shellParameterDepth == 0 && take("#") { return lineComment() }
        if take("$'") { return quoted(until: "'", multiline: true) }
        if take("$\"") || take("\"") {
            return quoted(until: "\"", multiline: true,
                          interpolations: [Self.dollarBraces, Self.shellCommand], depth: depth)
        }
        if take("'") { return quoted(until: "'", multiline: true, escape: nil) }
        if take("`") { return quoted(until: "`", multiline: true) }
        if take("\\") {
            remaining = remaining.dropFirst()
            return nil
        }
        if remaining.first == "$" {
            remaining.removeFirst()
            if remaining.first == "{" {
                shellParameterDepth += 1
            } else {
                remaining = remaining.drop(while: Self.isShellNameCharacter)
            }
            return nil
        } else if shellParameterDepth > 0 && remaining.first == "}" {
            shellParameterDepth -= 1
        }
        let word = remaining.prefix(while: Self.isShellNameCharacter)
        if !word.isEmpty {
            remaining = remaining[word.endIndex...]
            return remaining.first != "$" && Self.keywords.contains(word) ? .keyword : nil
        }
        return nil
    }

    private static func isShellNameCharacter(_ character: Character) -> Bool {
        character != "$" && isIdentifierCharacter(character)
    }

    override func skipInterpolation(_ interpolation: Interpolation, depth: Int) {
        let outerWordStart = shellWordStart
        let outerParameterDepth = shellParameterDepth
        shellWordStart = true
        if interpolation.opening == "{" { shellParameterDepth += 1 }
        super.skipInterpolation(interpolation, depth: depth)
        shellWordStart = outerWordStart
        shellParameterDepth = outerParameterDepth
    }
}
