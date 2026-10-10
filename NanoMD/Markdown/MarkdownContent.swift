nonisolated struct MarkdownContent: Sendable {
    let blocks: [MarkdownBlock]
}

nonisolated indirect enum MarkdownBlock: Sendable {
    case paragraph([MarkdownRun])
    case heading(level: Int, runs: [MarkdownRun])
    case code(String)
    case quote([MarkdownBlock])
    case list(start: UInt?, items: [MarkdownListItem])
    case table(MarkdownTable)
    case thematicBreak
    case literal(String)
}

nonisolated struct MarkdownListItem: Sendable {
    let checkbox: String?
    let blocks: [MarkdownBlock]
}

nonisolated struct MarkdownTable: Sendable {
    enum Alignment: Sendable {
        case left
        case center
        case right
    }

    struct Row: Sendable {
        let cells: [[MarkdownRun]]
    }

    let columnAlignments: [Alignment]
    let header: Row
    let rows: [Row]
}

nonisolated struct MarkdownRun: Sendable {
    let text: String
    var style: Style = []
    var destination: String?

    struct Style: OptionSet, Sendable {
        let rawValue: Int

        static let emphasis = Self(rawValue: 1 << 0)
        static let strong = Self(rawValue: 1 << 1)
        static let code = Self(rawValue: 1 << 2)
    }
}
