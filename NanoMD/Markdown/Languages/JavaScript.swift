nonisolated class JavaScriptHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["js", "javascript"] }

    private var context = JavaScriptContext()
    var expectsExpression: Bool { context.expectsExpression }

    func finishEmbeddedExpression(with delimiter: Substring) {
        context.record(delimiter, kind: .quotedText)
    }

    override func advance(depth: Int) -> Kind? {
        let start = remaining.startIndex
        let kind = super.advance(depth: depth)
        context.record(source[start..<remaining.startIndex], kind: kind)
        return kind
    }

    override func languageToken(depth: Int) -> Kind? {
        if remaining.startIndex == source.startIndex && take("#!") { return lineComment() }
        if let comment = slashComment() { return comment }
        if take("`") {
            return quoted(until: "`", multiline: true, interpolations: [Self.dollarBraces], depth: depth)
        }
        if context.expectsExpression && take("/") { return javaScriptRegex() }
        if take("++") || take("--") { return .symbol }
        return simpleQuote()
    }

    private func javaScriptRegex() -> Kind {
        var inCharacterClass = false
        while let first = remaining.first, !first.isNewline {
            remaining.removeFirst()
            switch first {
            case "\\":
                if let escaped = remaining.first, !escaped.isNewline { remaining.removeFirst() }
            case "[":
                inCharacterClass = true
            case "]":
                inCharacterClass = false
            case "/" where !inCharacterClass:
                remaining = remaining.drop(while: Self.isIdentifierCharacter)
                return .quotedText
            default:
                break
            }
        }
        return .quotedText
    }

    override func skipInterpolation(_ interpolation: Interpolation, depth: Int) {
        let outerContext = context
        context = JavaScriptContext(statementStart: false)
        super.skipInterpolation(interpolation, depth: depth)
        context = outerContext
    }

    private struct JavaScriptContext: Sendable {
        private static let controlHeads: Set<Substring> = ["if", "while", "for", "with", "switch", "catch"]
        private static let expressionLeaders: Set<Substring> = [
            "return", "throw", "case", "yield", "await", "void", "typeof", "delete", "in",
            "instanceof", "of", "new"
        ]

        private var afterControlHead = false
        private var afterMemberAccess = false
        private var parentheses: [Bool] = []
        private var statementBraces: [Bool] = []
        private var statementStart: Bool
        private(set) var expectsExpression = true

        init(statementStart: Bool = true) {
            self.statementStart = statementStart
        }

        mutating func record(_ token: Substring, kind: Kind?) {
            guard kind != .comment, token.first?.isWhitespace == false else { return }
            defer {
                afterControlHead = !afterMemberAccess && Self.controlHeads.contains(token)
                afterMemberAccess = token == "."
            }
            let wasStatementStart = statementStart
            statementStart = false
            switch token {
            case "(":
                parentheses.append(afterControlHead)
                expectsExpression = true
            case ")":
                statementStart = parentheses.popLast() ?? false
                expectsExpression = statementStart
            case "{":
                statementBraces.append(wasStatementStart)
                statementStart = true
                expectsExpression = true
            case "}":
                statementStart = statementBraces.popLast() ?? false
                expectsExpression = statementStart
            case ";", "else", "do", "try", "finally":
                statementStart = !afterMemberAccess
                expectsExpression = statementStart
            case "++", "--":
                break
            case "]", ".":
                expectsExpression = false
            default:
                expectsExpression = kind == .symbol || (!afterMemberAccess && Self.expressionLeaders.contains(token))
            }
        }
    }
}
