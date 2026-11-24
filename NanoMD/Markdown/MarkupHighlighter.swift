nonisolated class MarkupHighlighter: CodeBlockHighlighter {
    static func isMarkupSpace(_ character: Character) -> Bool {
        switch character {
        case " ", "\t", "\n", "\r", "\r\n", "\u{0C}": true
        default: false
        }
    }

    class func startsTagName(_ character: Character) -> Bool {
        character.isASCII && character.isLetter
    }

    class func continuesReferenceName(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber)
    }

    final override func scanTokens() {
        while !Task.isCancelled, let first = remaining.first {
            switch first {
            case "<":
                if scanComment() || scanSpecialMarkup() { continue }
                if take("<!", as: .symbol) {
                    scanDeclaration()
                } else {
                    scanTag()
                }
            case "&":
                scanReference()
            default:
                consume(to: remaining.prefix { $0 != "<" && $0 != "&" }.endIndex)
            }
        }
    }

    func scanSpecialMarkup() -> Bool { false }

    final func consume(to end: String.Index, as kind: Kind? = nil) {
        let start = remaining.startIndex
        remaining = remaining[end...]
        record(from: start, as: kind)
    }

    @discardableResult
    final func take(_ marker: String, as kind: Kind) -> Bool {
        let start = remaining.startIndex
        guard take(marker) else { return false }
        record(from: start, as: kind)
        return true
    }

    private func scanComment() -> Bool {
        let start = remaining.startIndex
        guard take("<!--") else { return false }
        let end = remaining.firstRange(of: "-->")?.upperBound ?? remaining.endIndex
        remaining = remaining[end...]
        record(from: start, as: .comment)
        return true
    }

    private func scanTag() {
        let closing = remaining.hasPrefix("</")
        let afterOpener = remaining.dropFirst(closing ? 2 : 1)
        guard let first = afterOpener.first, Self.startsTagName(first) else {
            consume(to: remaining.dropFirst().startIndex)
            return
        }
        let name = afterOpener.prefix { !Self.isMarkupSpace($0) && !"/><".contains($0) }
        consume(to: name.startIndex, as: .symbol)
        consume(to: name.endIndex, as: .keyword)
        scanTagBody(named: name, closing: closing)
    }

    func scanTagBody(named name: Substring, closing: Bool) {
        scanAttributes()
    }

    @discardableResult
    final func scanAttributes(
        endingWith terminator: String = ">",
        allowUnquotedValues: Bool = false,
        onAttribute: (Substring, Substring) -> Void = { _, _ in }
    ) -> Bool {
        while let first = remaining.first {
            if take(terminator, as: .symbol) || (terminator == ">" && take("/>", as: .symbol)) { return true }
            if first == "<" { break }
            if Self.isMarkupSpace(first) { skipSpace(); continue }
            let name = remaining.prefix {
                !Self.isMarkupSpace($0) && !"/><=\"'".contains($0) && !(terminator == "?>" && $0 == "?")
            }
            guard !name.isEmpty else {
                consume(to: remaining.dropFirst().startIndex, as: .symbol)
                continue
            }
            consume(to: name.endIndex, as: .keyword)
            skipSpace()
            var value: Substring = ""
            if take("=", as: .symbol) {
                skipSpace()
                if let quote = remaining.first, quote == "\"" || quote == "'" {
                    value = scanQuotedValue(quote)
                } else {
                    value = remaining.prefix { !Self.isMarkupSpace($0) && $0 != "<" && $0 != ">" }
                    consume(to: value.endIndex, as: allowUnquotedValues ? .quotedText : nil)
                }
            }
            onAttribute(name, value)
        }
        return false
    }

    private func skipSpace() {
        consume(to: remaining.prefix(while: Self.isMarkupSpace).endIndex)
    }

    @discardableResult
    private func scanQuotedValue(_ quote: Character) -> Substring {
        let value = remaining.dropFirst().prefix { $0 != quote }
        consume(to: remaining[value.endIndex...].dropFirst().startIndex, as: .quotedText)
        return value
    }

    final func scanReference() {
        let body = remaining.dropFirst()
        var name = body
        if name.first == "#" {
            name = name.dropFirst()
            let hex = name.first == "x" || name.first == "X"
            if hex { name = name.dropFirst() }
            name = name.prefix { $0.isASCII && (hex ? $0.isHexDigit : $0.isNumber) }
        } else if let first = name.first, Self.startsTagName(first) {
            name = name.prefix(while: Self.continuesReferenceName)
        } else {
            consume(to: body.startIndex)
            return
        }
        let tail = remaining[name.endIndex...]
        if !name.isEmpty && tail.first == ";" {
            consume(to: tail.dropFirst().startIndex, as: .symbol)
        } else {
            consume(to: body.startIndex)
        }
    }

    private func scanDeclaration() {
        // An XML doctype's internal subset can contain declarations with their own closing brackets.
        let punctuation = "<>![](),|%#*+?="
        var subsetDepth = 0
        while let first = remaining.first {
            if first == "<", scanComment() || scanSpecialMarkup() { continue }
            if first == "'" || first == "\"" {
                scanQuotedValue(first)
            } else if Self.isMarkupSpace(first) {
                skipSpace()
            } else if punctuation.contains(first) {
                consume(to: remaining.dropFirst().startIndex, as: .symbol)
                if first == ">" && subsetDepth == 0 { return }
                if first == "[" { subsetDepth += 1 }
                if first == "]" && subsetDepth > 0 { subsetDepth -= 1 }
            } else {
                let word = remaining.prefix { !Self.isMarkupSpace($0) && !punctuation.contains($0) && $0 != "'" && $0 != "\"" }
                consume(to: word.endIndex, as: .keyword)
            }
        }
    }
}
