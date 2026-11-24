nonisolated final class CSSHighlighter: CodeBlockHighlighter {
    override class var fenceTags: [String] { ["css"] }

    private var blockDepth = 0

    override func languageToken(depth: Int) -> Kind? {
        if let comment = blockComment() { return comment }
        if let quote = simpleQuote() { return quote }
        guard let first = remaining.first else { return nil }
        switch first {
        case "{": blockDepth += 1
        case "}": blockDepth = max(0, blockDepth - 1)
        case "!":
            let priority = remaining.dropFirst().drop(while: \.isWhitespace).prefix(while: Self.isNameCharacter)
            if priority.lowercased() == "important" {
                remaining = remaining[priority.endIndex...]
                return .keyword
            }
        case "@", "#", ".":
            let tail = remaining.dropFirst()
            guard let next = tail.first, Self.isNameCharacter(next) || next == "\\",
                  first != "." || !next.isNumber else { break }
            remaining = tail
            _ = consumeName()
            return .keyword
        default:
            guard Self.isNameCharacter(first) || first == "\\" else { return nil }
            if first == "-", remaining.dropFirst().first.map(Self.isNameCharacter) != true,
               !remaining.hasPrefix("-\\") { return nil }
            let name = consumeName()
            if first.isNumber { return nil }
            if remaining.first == "(" {
                if name.lowercased() == "url" {
                    let argument = remaining.dropFirst().drop(while: \.isWhitespace)
                    if argument.first != "\"" && argument.first != "'" {
                        // An unquoted URL is a single CSS token, including any slashes or hashes.
                        remaining = argument
                        while let character = remaining.first {
                            remaining.removeFirst()
                            if character == ")" { break }
                            if character == "\\" { remaining = remaining.dropFirst() }
                        }
                        return .quotedText
                    }
                }
                return .keyword
            }
            let next = remaining.drop(while: \.isWhitespace).first
            if blockDepth == 0 || name.hasPrefix("--") || next == ":" || next == "{" {
                return .keyword
            }
            return nil
        }
        remaining.removeFirst()
        return .symbol
    }

    private static func isNameCharacter(_ character: Character) -> Bool {
        !character.isASCII || character.isLetter || character.isNumber || character == "-" || character == "_"
    }

    private func consumeName() -> Substring {
        let start = remaining.startIndex
        while let first = remaining.first {
            if Self.isNameCharacter(first) {
                remaining.removeFirst()
            } else if take("\\") {
                guard let escaped = remaining.first, !escaped.isNewline else { break }
                let hex = remaining.prefix(6).prefix(while: { $0.isASCII && $0.isHexDigit })
                if hex.isEmpty {
                    remaining.removeFirst()
                } else {
                    remaining = remaining[hex.endIndex...]
                    if remaining.first?.isWhitespace == true { remaining.removeFirst() }
                }
            } else {
                break
            }
        }
        return source[start..<remaining.startIndex]
    }
}
