import AppKit

struct MarkdownTextRenderer {
    func render(_ content: MarkdownContent) async throws -> NSAttributedString {
        let output = NSMutableAttributedString(string: "")
        for block in content.blocks {
            try await append(block, to: output)
        }
        return NSAttributedString(attributedString: output)
    }

    private func append(
        _ block: MarkdownBlock,
        to output: NSMutableAttributedString,
        indent: CGFloat = 0,
        quoteDepth: Int = 0,
        marker: String = ""
    ) async throws {
        try Task.checkCancellation()
        await Task.yield()
        switch block {
        case let .paragraph(runs):
            appendParagraph(runs, to: output, indent: indent, quoteDepth: quoteDepth, marker: marker)
        case let .heading(level, runs):
            let sizes: [CGFloat] = [30, 25, 21, 18, 16, 15]
            let font = NSFont.systemFont(ofSize: sizes[min(max(level, 1), 6) - 1], weight: .semibold)
            appendParagraph(runs, to: output, font: font, indent: indent, quoteDepth: quoteDepth, marker: marker)
        case let .code(text), let .literal(text):
            appendParagraph(
                [MarkdownRun(text: text, style: .code)], to: output,
                indent: indent, quoteDepth: quoteDepth, marker: marker, isLiteralBlock: true
            )
        case let .quote(blocks):
            for (index, child) in blocks.enumerated() {
                try await append(child, to: output, indent: indent + 20, quoteDepth: quoteDepth + 1,
                                 marker: index == 0 ? marker : "")
            }
        case let .list(start, items):
            if !marker.isEmpty {
                appendParagraph([], to: output, indent: indent, quoteDepth: quoteDepth, marker: marker)
            }
            for (index, item) in items.enumerated() {
                let bullet = start.map { "\($0 + UInt(index))." } ?? "•"
                let prefix = item.checkbox.map { "\(bullet) \($0)\t" } ?? "\(bullet)\t"
                if item.blocks.isEmpty {
                    appendParagraph([], to: output, indent: indent + 24, quoteDepth: quoteDepth, marker: prefix)
                }
                for (blockIndex, child) in item.blocks.enumerated() {
                    try await append(child, to: output, indent: indent + 24, quoteDepth: quoteDepth,
                                     marker: blockIndex == 0 ? prefix : "")
                }
            }
        case let .table(table):
            if !marker.isEmpty {
                appendParagraph([], to: output, indent: indent, quoteDepth: quoteDepth, marker: marker)
            }
            try await appendTable(table, to: output, indent: indent, quoteDepth: quoteDepth)
        case .thematicBreak:
            appendParagraph([MarkdownRun(text: "────────────")], to: output,
                            indent: indent, quoteDepth: quoteDepth, marker: marker)
        }
    }

    private func appendTable(
        _ content: MarkdownTable,
        to output: NSMutableAttributedString,
        indent: CGFloat,
        quoteDepth: Int
    ) async throws {
        guard !content.columnAlignments.isEmpty else { return }

        let table = NSTextTable()
        table.numberOfColumns = content.columnAlignments.count
        table.layoutAlgorithm = .fixedLayoutAlgorithm
        table.collapsesBorders = false
        table.hidesEmptyCells = false
        table.setWidth(indent, type: .absoluteValueType, for: .margin, edge: .minX)

        for (rowIndex, row) in ([content.header] + content.rows).enumerated() {
            try Task.checkCancellation()
            await Task.yield()
            let isHeader = rowIndex == 0
            let font = NSFont.systemFont(ofSize: 15, weight: isHeader ? .semibold : .regular)

            for (columnIndex, alignment) in content.columnAlignments.enumerated() {
                let cell = NSTextTableBlock(
                    table: table, startingRow: rowIndex, rowSpan: 1,
                    startingColumn: columnIndex, columnSpan: 1
                )
                cell.setWidth(8, type: .absoluteValueType, for: .padding)
                cell.setWidth(0.5, type: .absoluteValueType, for: .border)
                cell.setBorderColor(.separatorColor)
                cell.verticalAlignment = .topAlignment
                if isHeader {
                    cell.backgroundColor = .quaternaryLabelColor
                }

                let paragraph = NSMutableParagraphStyle()
                paragraph.textBlocks = [cell]
                paragraph.lineSpacing = 4
                paragraph.alignment = switch alignment {
                case .left: .left
                case .center: .center
                case .right: .right
                }
                let base: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: quoteDepth > 0 ? NSColor.secondaryLabelColor : NSColor.textColor,
                    .paragraphStyle: paragraph
                ]
                let runs = columnIndex < row.cells.count ? row.cells[columnIndex] : []
                appendRuns(runs, to: output, font: font, base: base)
                // Even an empty cell needs a paragraph carrying its table block.
                output.append(NSAttributedString(string: "\n", attributes: base))
            }
        }

        // Keep the gap after a table outside its cell layout and borders.
        let spacing = NSMutableParagraphStyle()
        spacing.minimumLineHeight = 12
        spacing.maximumLineHeight = 12
        output.append(NSAttributedString(string: "\n", attributes: [
            .font: NSFont.systemFont(ofSize: 1),
            .paragraphStyle: spacing
        ]))
    }

    private func appendParagraph(
        _ runs: [MarkdownRun],
        to output: NSMutableAttributedString,
        font: NSFont = .systemFont(ofSize: 15),
        indent: CGFloat,
        quoteDepth: Int,
        marker: String,
        isLiteralBlock: Bool = false
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.paragraphSpacing = isLiteralBlock ? 0 : 12
        paragraph.lineSpacing = isLiteralBlock ? 2 : 4
        paragraph.headIndent = indent
        paragraph.firstLineHeadIndent = marker.isEmpty ? indent : max(0, indent - 24)
        paragraph.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
        paragraph.defaultTabInterval = 32
        if isLiteralBlock {
            let block = RoundedCodeBlock()
            block.setContentWidth(100, type: .percentageValueType)
            block.backgroundColor = .quaternaryLabelColor
            block.setWidth(4, type: .absoluteValueType, for: .padding)
            paragraph.textBlocks = [block]
        }

        let base: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: quoteDepth > 0 ? NSColor.secondaryLabelColor : NSColor.textColor,
            .paragraphStyle: paragraph
        ]
        let prefix = marker + (quoteDepth > 0 ? "│ " : "")
        output.append(NSAttributedString(string: prefix, attributes: base))
        appendRuns(runs, to: output, font: font, base: base, usesInlineCodeBackground: !isLiteralBlock)
        if runs.last?.text.hasSuffix("\n") != true || runs.last?.destination != nil {
            output.append(NSAttributedString(string: "\n", attributes: base))
        }
        if isLiteralBlock {
            let spacing = NSMutableParagraphStyle()
            spacing.lineSpacing = paragraph.lineSpacing
            output.append(NSAttributedString(string: "\n", attributes: [
                .font: font,
                .paragraphStyle: spacing
            ]))
        }
    }

    private func appendRuns(
        _ runs: [MarkdownRun],
        to output: NSMutableAttributedString,
        font: NSFont,
        base: [NSAttributedString.Key: Any],
        usesInlineCodeBackground: Bool = true
    ) {
        for (index, run) in runs.enumerated() {
            var attributes = base
            var runFont = run.style.contains(.code)
                ? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular) : font
            if run.style.contains(.strong) {
                runFont = NSFontManager.shared.convert(runFont, toHaveTrait: .boldFontMask)
            }
            if run.style.contains(.emphasis) {
                runFont = NSFontManager.shared.convert(runFont, toHaveTrait: .italicFontMask)
            }
            attributes[.font] = runFont
            if run.style.contains(.code), usesInlineCodeBackground {
                attributes[.backgroundColor] = NSColor.quaternaryLabelColor
            }
            if let destination = run.destination {
                if let url = ReaderLinkPolicy.allowedURL(destination) {
                    attributes[.link] = url
                    attributes[.toolTip] = destination
                } else {
                    output.append(NSAttributedString(string: run.text, attributes: attributes))
                    if index + 1 == runs.count || runs[index + 1].destination != destination {
                        output.append(NSAttributedString(string: " (\(destination))", attributes: base))
                    }
                    continue
                }
            }
            output.append(NSAttributedString(string: run.text, attributes: attributes))
        }
    }
}

private nonisolated final class RoundedCodeBlock: NSTextBlock {
    override func drawBackground(
        withFrame frameRect: NSRect,
        in controlView: NSView,
        characterRange charRange: NSRange,
        layoutManager: NSLayoutManager
    ) {
        guard let backgroundColor else { return }
        backgroundColor.setFill()
        NSBezierPath(roundedRect: frameRect, xRadius: 3, yRadius: 3).fill()
    }
}
