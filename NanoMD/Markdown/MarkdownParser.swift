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
        let body = frontMatter?.body ?? source
        let sourceIndex = MarkdownSourceIndex(body, baseOffset: frontMatter?.bodyOffset ?? 0)
        let document = Document(parsing: body, options: [.disableSmartOpts])
        try validateComplexity(document)
        var blocks = try document.children.map { try block($0, sourceIndex: sourceIndex) }
        if let frontMatter {
            blocks.insert(.located(.frontMatter(frontMatter.metadata), frontMatter.metadataSpan), at: 0)
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

    private func block(_ node: any Markup, sourceIndex: MarkdownSourceIndex) throws -> MarkdownBlock {
        let content = try blockContent(node, sourceIndex: sourceIndex)
        return sourceIndex.contentSpan(for: node).map { .located(content, $0) } ?? content
    }

    private func blockContent(_ node: any Markup, sourceIndex: MarkdownSourceIndex) throws -> MarkdownBlock {
        try Task.checkCancellation()
        switch node {
        case let heading as Heading:
            return .heading(level: heading.level, runs: try inlineChildren(heading, sourceIndex: sourceIndex))
        case let paragraph as Paragraph:
            return .paragraph(try inlineChildren(paragraph, sourceIndex: sourceIndex))
        case let code as CodeBlock:
            return .code(code.code)
        case let quote as BlockQuote:
            return .quote(try quote.children.map { try block($0, sourceIndex: sourceIndex) })
        case let list as OrderedList:
            return .list(start: list.startIndex, items: try list.children.map { try listItem($0, sourceIndex: sourceIndex) })
        case let list as UnorderedList:
            return .list(start: nil, items: try list.children.map { try listItem($0, sourceIndex: sourceIndex) })
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
                header: MarkdownTable.Row(cells: try table.head.cells.map { try tableCell($0, sourceIndex: sourceIndex) }),
                rows: try table.body.rows.map { row in
                    try Task.checkCancellation()
                    return MarkdownTable.Row(cells: try row.cells.map { try tableCell($0, sourceIndex: sourceIndex) })
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

    private func tableCell(_ node: any Markup, sourceIndex: MarkdownSourceIndex) throws -> MarkdownTable.Cell {
        MarkdownTable.Cell(runs: try inlineChildren(node, sourceIndex: sourceIndex), sourceSpan: sourceIndex.span(for: node))
    }

    private func listItem(_ node: any Markup, sourceIndex: MarkdownSourceIndex) throws -> MarkdownListItem {
        let checkbox: String?
        switch (node as? ListItem)?.checkbox {
        case .checked: checkbox = "[x]"
        case .unchecked: checkbox = "[ ]"
        case nil: checkbox = nil
        }
        return MarkdownListItem(checkbox: checkbox, blocks: try node.children.map { try block($0, sourceIndex: sourceIndex) })
    }

    private func inlineChildren(
        _ node: any Markup,
        sourceIndex: MarkdownSourceIndex,
        style: MarkdownRun.Style = [],
        destination: String? = nil
    ) throws -> [MarkdownRun] {
        try node.children.flatMap { child in
            var runs = try inline(child, sourceIndex: sourceIndex, style: style, destination: destination)
            for index in runs.indices where runs[index].sourceSpan == nil {
                runs[index].sourceSpan = sourceIndex.contentSpan(for: child)
            }
            return runs
        }
    }

    private func inline(
        _ node: any Markup,
        sourceIndex: MarkdownSourceIndex,
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
            return try inlineChildren(node, sourceIndex: sourceIndex, style: style.union(.emphasis), destination: destination)
        case is Strong:
            return try inlineChildren(node, sourceIndex: sourceIndex, style: style.union(.strong), destination: destination)
        case let code as InlineCode:
            return [MarkdownRun(text: code.code, style: style.union(.code), destination: destination)]
        case let link as Link:
            var runs = try inlineChildren(link, sourceIndex: sourceIndex, style: style, destination: link.destination)
            for index in runs.indices { runs[index].linkSpan = sourceIndex.span(for: link) }
            return runs
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
