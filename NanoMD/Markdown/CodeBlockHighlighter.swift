import Foundation

nonisolated class CodeBlockHighlighter {
    typealias Highlight = MarkdownCodeBlock.Highlight
    typealias Kind = Highlight.Kind

    private static let languagesByFence: [String: CodeBlockHighlighter.Type] = {
        let languages: [CodeBlockHighlighter.Type] = [
            JavaHighlighter.self, JavaScriptHighlighter.self, TypeScriptHighlighter.self, TSXHighlighter.self,
            CSSHighlighter.self, KotlinHighlighter.self, SwiftHighlighter.self,
            PythonHighlighter.self, RubyHighlighter.self, CHighlighter.self, CPlusPlusHighlighter.self,
            CSharpHighlighter.self, BashHighlighter.self, HTMLHighlighter.self, XMLHighlighter.self
        ]
        return Dictionary(uniqueKeysWithValues: languages.flatMap { language in
            language.fenceTags.map { ($0, language) }
        })
    }()

    class var fenceTags: [String] { [] }

    static func highlights(in source: String, fence: String?) -> [Highlight] {
        let tag = fence?.split(whereSeparator: \.isWhitespace).first?.lowercased()
        if tag == "text" || tag == "plaintext" { return [] }
        let language = tag.flatMap { languagesByFence[$0] } ?? CodeBlockHighlighter.self
        let highlighter = language.init(source)
        highlighter.scanTokens()
        return highlighter.highlights
    }

    @concurrent
    static func fileHighlights(in source: String, language: String) async -> [Highlight] {
        guard !Task.isCancelled, source.utf8.count <= MarkdownParser.maximumSourceBytes else { return [] }
        return highlights(in: source, fence: language)
    }

    struct Interpolation: Sendable {
        let prefix: String
        let opening: Character
        let closing: Character
        var doubledOpeningIsText = false
    }

    // Present in at least four of Java, JavaScript, Kotlin, Swift, and Python.
    static let keywords: Set<Substring> = [
        "as", "break", "case", "catch", "class", "continue", "do", "else", "enum", "finally",
        "for", "if", "import", "in", "package", "private", "public", "return", "super", "throw",
        "try", "var", "while"
    ]
    private static let symbols = Set("()[]{}.,:;+-*/%=<>!&|^~?@")
    static let dollarBraces = Interpolation(prefix: "${", opening: "{", closing: "}")
    static let doubledBraces = Interpolation(
        prefix: "{", opening: "{", closing: "}", doubledOpeningIsText: true
    )

    let source: String
    var remaining: Substring
    private var highlights: [Highlight] = []
    private var utf16Offset = 0

    required init(_ source: String) {
        self.source = source
        remaining = source[...]
    }

    func scanTokens() {
        while !remaining.isEmpty && !Task.isCancelled {
            let start = remaining.startIndex
            let kind = advance()
            record(from: start, as: kind)
        }
    }

    final func record(from start: String.Index, as kind: Kind?) {
        let length = source[start..<remaining.startIndex].utf16.count
        let range = NSRange(location: utf16Offset, length: length)
        utf16Offset += length
        guard let kind, length > 0 else { return }
        if kind == .symbol, let previous = highlights.last,
           previous.kind == .symbol, NSMaxRange(previous.range) == range.location {
            highlights[highlights.count - 1] = Highlight(kind: kind, range: NSUnionRange(previous.range, range))
        } else {
            highlights.append(Highlight(kind: kind, range: range))
        }
    }

    func advance(depth: Int = 0) -> Kind? {
        guard let first = remaining.first else { return nil }
        let start = remaining.startIndex
        let special = languageToken(depth: depth)
        // Some language rules consume code that has no highlight, such as a number.
        return remaining.startIndex == start ? sharedToken(first) : special
    }

    private func sharedToken(_ first: Character) -> Kind? {
        if Self.isIdentifierCharacter(first) {
            let word = remaining.prefix(while: Self.isIdentifierCharacter)
            remaining = remaining[word.endIndex...]
            return Self.isKeyword(word) ? .keyword : nil
        }
        remaining.removeFirst()
        return Self.symbols.contains(first) ? .symbol : nil
    }

    class func isKeyword(_ word: Substring) -> Bool {
        keywords.contains(word)
    }

    static func isIdentifierCharacter(_ character: Character) -> Bool {
        character == "$" || character.unicodeScalars.allSatisfy {
            $0.properties.isXIDContinue || $0.properties.isJoinControl
        }
    }

    final func take(_ prefix: String) -> Bool {
        guard remaining.hasPrefix(prefix) else { return false }
        remaining = remaining.dropFirst(prefix.count)
        return true
    }

    final func toEnd() {
        remaining = remaining[remaining.endIndex...]
    }

    final func lineComment(continuedLines: Bool = false) -> Kind {
        if continuedLines {
            while let first = remaining.first, !first.isNewline {
                if first == "\\", remaining.dropFirst().first?.isNewline == true {
                    remaining = remaining.dropFirst(2)
                } else {
                    remaining.removeFirst()
                }
            }
        } else {
            remaining = remaining.drop(while: { !$0.isNewline })
        }
        return .comment
    }

    final func slashComment(nested: Bool = false, continuedLines: Bool = false) -> Kind? {
        if take("//") { return lineComment(continuedLines: continuedLines) }
        return blockComment(nested: nested)
    }

    final func blockComment(nested: Bool = false) -> Kind? {
        guard take("/*") else { return nil }
        var level = 1
        while !remaining.isEmpty && level > 0 {
            if take("*/") {
                level -= 1
            } else if nested && take("/*") {
                level += 1
            } else {
                remaining.removeFirst()
            }
        }
        return .comment
    }

    final func simpleQuote() -> Kind? {
        guard let first = remaining.first, first == "\"" || first == "'" else { return nil }
        remaining.removeFirst()
        return quoted(until: String(first))
    }

    final func quoted(
        until delimiter: String,
        multiline: Bool = false,
        escape: String? = "\\",
        doubledDelimiter: Bool = false,
        nestedOpener: Character? = nil,
        interpolations: [Interpolation] = [],
        depth: Int = 0
    ) -> Kind {
        var level = 0
        while let first = remaining.first, multiline || !first.isNewline {
            if take(delimiter) {
                if doubledDelimiter && take(delimiter) { continue }
                if level == 0 { break }
                level -= 1
            } else if let interpolation = interpolations.first(where: { remaining.hasPrefix($0.prefix) }) {
                if interpolation.doubledOpeningIsText && take("{{") { continue }
                _ = take(interpolation.prefix)
                skipInterpolation(interpolation, depth: depth)
            } else if let escape, take(escape) {
                remaining = remaining.dropFirst()
            } else {
                if first == nestedOpener { level += 1 }
                remaining.removeFirst()
            }
        }
        return .quotedText
    }

    func skipInterpolation(_ interpolation: Interpolation, depth: Int) {
        // Incomplete snippets can contain arbitrarily many nested literal delimiters.
        guard depth < 64 else { toEnd(); return }
        var level = 1
        while let first = remaining.first {
            _ = advance(depth: depth + 1)
            if first == interpolation.opening {
                level += 1
            } else if first == interpolation.closing {
                level -= 1
                if level == 0 { break }
            }
        }
    }

    func languageToken(depth: Int) -> Kind? {
        if take("#") { return lineComment() }
        if let comment = slashComment() { return comment }
        guard let quote = remaining.first, quote == "\"" || quote == "'" || quote == "`" else {
            return nil
        }
        let triple = quote != "`" && remaining.starts(with: repeatElement(quote, count: 3))
        let delimiter = String(repeating: String(quote), count: triple ? 3 : 1)
        _ = take(delimiter)
        return quoted(until: delimiter, multiline: triple || quote == "`")
    }
}
