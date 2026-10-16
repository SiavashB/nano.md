import Foundation
import Markdown

actor MarkdownParser {
    static let maximumSourceBytes = 1_048_576

    func parse(_ source: String) throws -> MarkdownContent {
        try Task.checkCancellation()
        guard source.utf8.count <= Self.maximumSourceBytes else {
            throw MarkdownRenderingError.tooLarge
        }

        let frontMatter = MarkdownFrontMatter(source)
        let document = Document(parsing: frontMatter?.body ?? source, options: [.disableSmartOpts])
        try validateComplexity(document)
        var blocks = try document.children.map(block)
        if let frontMatter {
            blocks.insert(.frontMatter(frontMatter.metadata), at: 0)
        }
        let content = MarkdownContent(blocks: blocks)
        try Task.checkCancellation()
        return content
    }

    private func validateComplexity(_ document: Document) throws {
        var pending: [(node: any Markup, depth: Int)] = [(document, 0)]
        var count = 0
        while let (node, depth) = pending.popLast() {
            try Task.checkCancellation()
            count += 1
            guard depth <= 64, count <= 50_000 else {
                throw MarkdownRenderingError.tooComplex
            }
            pending.append(contentsOf: node.children.map { ($0, depth + 1) })
        }
    }

    private func block(_ node: any Markup) throws -> MarkdownBlock {
        try Task.checkCancellation()
        switch node {
        case let heading as Heading:
            return .heading(level: heading.level, runs: try inlineChildren(heading))
        case let paragraph as Paragraph:
            return .paragraph(try inlineChildren(paragraph))
        case let code as CodeBlock:
            return .code(code.code)
        case let quote as BlockQuote:
            return .quote(try quote.children.map(block))
        case let list as OrderedList:
            return .list(start: list.startIndex, items: try list.children.map(listItem))
        case let list as UnorderedList:
            return .list(start: nil, items: try list.children.map(listItem))
        case let table as Table:
            let alignments: [MarkdownTable.Alignment] = table.columnAlignments.map {
                switch $0 {
                case .center: .center
                case .right: .right
                case .left, nil: .left
                }
            }
            return .table(MarkdownTable(
                columnAlignments: alignments,
                header: MarkdownTable.Row(cells: try table.head.cells.map { try inlineChildren($0) }),
                rows: try table.body.rows.map { row in
                    try Task.checkCancellation()
                    return MarkdownTable.Row(cells: try row.cells.map { try inlineChildren($0) })
                }
            ))
        case is ThematicBreak:
            return .thematicBreak
        case let html as HTMLBlock:
            return .literal(html.rawHTML)
        default:
            return .literal(node.format())
        }
    }

    private func listItem(_ node: any Markup) throws -> MarkdownListItem {
        let checkbox: String?
        switch (node as? ListItem)?.checkbox {
        case .checked: checkbox = "[x]"
        case .unchecked: checkbox = "[ ]"
        case nil: checkbox = nil
        }
        return MarkdownListItem(checkbox: checkbox, blocks: try node.children.map(block))
    }

    private func inlineChildren(
        _ node: any Markup,
        style: MarkdownRun.Style = [],
        destination: String? = nil
    ) throws -> [MarkdownRun] {
        try node.children.flatMap { try inline($0, style: style, destination: destination) }
    }

    private func inline(
        _ node: any Markup,
        style: MarkdownRun.Style,
        destination: String?
    ) throws -> [MarkdownRun] {
        try Task.checkCancellation()
        switch node {
        case let text as Text:
            return [MarkdownRun(text: text.string, style: style, destination: destination)]
        case is SoftBreak:
            return [MarkdownRun(text: " ", style: style, destination: destination)]
        case is LineBreak:
            return [MarkdownRun(text: "\u{2028}", style: style, destination: destination)]
        case is Emphasis:
            return try inlineChildren(node, style: style.union(.emphasis), destination: destination)
        case is Strong:
            return try inlineChildren(node, style: style.union(.strong), destination: destination)
        case let code as InlineCode:
            return [MarkdownRun(text: code.code, style: style.union(.code), destination: destination)]
        case let link as Link:
            return try inlineChildren(link, style: style, destination: link.destination)
        case let image as Image:
            let description = image.plainText.isEmpty ? "Image" : image.plainText
            let location = image.source.map { " (\($0))" } ?? ""
            return [MarkdownRun(text: "[\(description)\(location)]", style: style)]
        case let html as InlineHTML:
            return [MarkdownRun(text: html.rawHTML, style: style.union(.code))]
        default:
            return [MarkdownRun(text: node.format(), style: style)]
        }
    }
}

nonisolated enum MarkdownRenderingError: LocalizedError {
    case tooLarge
    case tooComplex

    var errorDescription: String? {
        switch self {
        case .tooLarge:
            String(localized: "Documents larger than 1 MiB are shown as source.")
        case .tooComplex:
            String(localized: "This document is too complex to format. Showing source instead.")
        }
    }
}
