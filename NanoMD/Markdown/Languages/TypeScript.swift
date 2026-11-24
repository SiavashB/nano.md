nonisolated class TypeScriptHighlighter: JavaScriptHighlighter {
    override class var fenceTags: [String] { ["ts", "typescript", "mts", "cts"] }

    private static let languageKeywords: Set<Substring> = [
        "abstract", "accessor", "any", "assert", "asserts", "async", "await", "bigint", "boolean",
        "const", "constructor", "debugger", "declare", "default", "delete", "export", "extends",
        "false", "from", "function", "get", "global", "implements", "infer", "instanceof", "interface",
        "intrinsic", "is", "keyof", "let", "module", "namespace", "never", "new", "null", "number",
        "object", "of", "out", "override", "protected", "readonly", "satisfies", "set", "static",
        "string", "switch", "symbol", "this", "true", "type", "typeof", "undefined", "unique",
        "unknown", "using", "void", "with", "yield"
    ]

    override class func isKeyword(_ word: Substring) -> Bool {
        super.isKeyword(word) || languageKeywords.contains(word)
    }
}

nonisolated final class TSXHighlighter: TypeScriptHighlighter {
    override class var fenceTags: [String] { ["tsx"] }

    private enum Section { case code, openingTag, closingTag, children }
    private var section = Section.code
    private var enclosing: [Section] = []
    private var typeArgumentDepth = 0

    override func advance(depth: Int) -> Kind? {
        guard depth == 0, let first = remaining.first else { return super.advance(depth: depth) }
        let start = remaining.startIndex
        switch section {
        case .code:
            if first == "<", expectsExpression, startsElement { return openElement() }
            if !enclosing.isEmpty {
                if first == "{" { enclosing.append(.code) }
                if first == "}" { section = enclosing.removeLast() }
            }
            return super.advance(depth: depth)
        case .children:
            if take("</") { section = .closingTag; return .symbol }
            if first == "<" { return openElement() }
            if first == "{" { return enterExpression() }
            remaining = remaining.drop(while: { $0 != "<" && $0 != "{" })
            return nil
        case .openingTag, .closingTag:
            if take("/>") || (section == .closingTag && take(">")) {
                typeArgumentDepth = 0
                section = enclosing.popLast() ?? .code
                // A completed JSX element acts as an operand for the next JavaScript slash.
                if section == .code { finishEmbeddedExpression(with: source[start..<remaining.startIndex]) }
                return .symbol
            }
            if section == .openingTag, take("<") {
                typeArgumentDepth += 1
                return .symbol
            }
            if typeArgumentDepth > 0 {
                // Function types can contain an arrow before the closing type argument bracket.
                if take("=>") { return .symbol }
                if take(">") {
                    typeArgumentDepth -= 1
                    return .symbol
                }
                return super.advance(depth: depth)
            }
            if take(">") { section = .children; return .symbol }
            if first == "{" { return enterExpression() }
            if first == "\"" || first == "'" {
                remaining.removeFirst()
                return quoted(until: String(first), multiline: true, escape: nil)
            }
            if Self.isIdentifierCharacter(first) {
                remaining = remaining.drop(while: { Self.isIdentifierCharacter($0) || "-.:".contains($0) })
                return .keyword
            }
            remaining.removeFirst()
            return first.isWhitespace ? nil : .symbol
        }
    }

    private var startsElement: Bool {
        let name = remaining.dropFirst()
        if name.first == ">" { return true } // A JSX fragment.
        guard let first = name.first, first.isLetter || first == "_" || first == "$" else { return false }
        let tail = name.drop(while: Self.isIdentifierCharacter).drop(while: \.isWhitespace)
        // In TSX, <T,> and <T extends U> introduce generic arrow functions.
        return tail.first != "," && tail.first != "=" && tail.prefix(while: Self.isIdentifierCharacter) != "extends"
    }

    private func openElement() -> Kind {
        enclosing.append(section)
        section = .openingTag
        remaining.removeFirst()
        return .symbol
    }

    private func enterExpression() -> Kind? {
        enclosing.append(section)
        section = .code
        return super.advance(depth: 0)
    }
}
