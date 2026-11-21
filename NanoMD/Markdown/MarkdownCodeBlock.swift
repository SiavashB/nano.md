import Foundation

nonisolated struct MarkdownCodeBlock: Sendable, Equatable, ExpressibleByStringLiteral {
    struct Highlight: Sendable, Equatable {
        enum Kind: Sendable, Equatable {
            case keyword
            case comment
            case symbol
            case quotedText
        }

        let kind: Kind
        /// UTF-16 offsets within the displayed code, before reader decorations.
        let range: NSRange
    }

    let text: String
    let highlights: [Highlight]

    init(_ text: String, language: String?) {
        self.text = text
        highlights = CodeBlockHighlighter.highlights(in: text, fence: language)
    }

    init(stringLiteral text: String) {
        self.init(text, language: nil)
    }
}
