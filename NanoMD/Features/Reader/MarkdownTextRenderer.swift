import AppKit

struct MarkdownTextRenderer {
    let theme: AppTheme
    let fontFamily: ReaderFont

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
        marker: String = "",
        sourceSpan: MarkdownSourceSpan? = nil
    ) async throws {
        try Task.checkCancellation()
        await Task.yield()
        let start = output.length
        defer {
            if let sourceSpan {
                let range = NSRange(location: start, length: output.length - start)
                var gaps: [NSRange] = []
                output.enumerateAttribute(.markdownSourceAnchor, in: range) { value, range, _ in
                    if value == nil { gaps.append(range) }
                }
                let string = output.string as NSString
                var end = output.length
                while end > start, CharacterSet.newlines.contains(Unicode.Scalar(string.character(at: end - 1)) ?? " ") {
                    end -= 1
                }
                for gap in gaps {
                    output.addAttribute(.markdownSourceAnchor, value: sourceSpan.range.lowerBound, range: gap)
                    let trailing = NSIntersectionRange(gap, NSRange(location: end, length: output.length - end))
                    if trailing.length > 0 {
                        output.addAttribute(.markdownSourceAnchor, value: sourceSpan.range.upperBound, range: trailing)
                    }
                }
            }
        }
        switch block {
        case let .located(content, span):
            try await append(content, to: output, indent: indent, quoteDepth: quoteDepth,
                             marker: marker, sourceSpan: span)
        case let .frontMatter(metadata):
            appendFrontMatter(metadata, sourceSpan: sourceSpan, to: output)
        case let .paragraph(runs):
            appendParagraph(runs, to: output, indent: indent, quoteDepth: quoteDepth, marker: marker)
        case let .heading(level, runs):
            let font = fontFamily.font(size: fontFamily.headingSize(level: level),
                                       weight: fontFamily.headingWeight)
            appendParagraph(runs, to: output, font: font, color: theme.primary,
                            indent: indent, quoteDepth: quoteDepth, marker: marker, isHeading: true)
        case let .code(text), let .literal(text):
            appendParagraph(
                [MarkdownRun(text: text, style: .code, sourceSpan: sourceSpan)], to: output,
                font: fontFamily.codeFont(size: 12),
                indent: indent, quoteDepth: quoteDepth, marker: marker, isLiteralBlock: true
            )
        case let .quote(blocks):
            for (index, child) in blocks.enumerated() {
                try await append(child, to: output, indent: indent + 20, quoteDepth: quoteDepth + 1,
                                 marker: index == 0 ? marker : "")
            }
        case let .list(startNumber, items):
            if !marker.isEmpty {
                appendParagraph([], to: output, indent: indent, quoteDepth: quoteDepth, marker: marker)
            }
            for (index, item) in items.enumerated() {
                let bullet = startNumber.map { "\($0 + UInt(index))." } ?? "•"
                let prefix = item.checkbox.map { "\(bullet) \($0)\t" } ?? "\(bullet)\t"
                if item.blocks.isEmpty {
                    appendParagraph([], to: output, indent: indent + 20, quoteDepth: quoteDepth, marker: prefix)
                }
                for (blockIndex, child) in item.blocks.enumerated() {
                    try await append(child, to: output, indent: indent + 20, quoteDepth: quoteDepth,
                                     marker: blockIndex == 0 ? prefix : "")
                }
            }
            if output.length > start,
               let style = output.attribute(.paragraphStyle, at: output.length - 1, effectiveRange: nil)
                    as? NSParagraphStyle,
               let spacing = style.mutableCopy() as? NSMutableParagraphStyle {
                spacing.paragraphSpacing = max(spacing.paragraphSpacing, 13)
                output.addAttribute(.paragraphStyle, value: spacing,
                                    range: (output.string as NSString).paragraphRange(
                                        for: NSRange(location: output.length - 1, length: 1)))
            }
        case let .table(table):
            if !marker.isEmpty {
                appendParagraph([], to: output, indent: indent, quoteDepth: quoteDepth, marker: marker)
            }
            try await appendTable(table, to: output, indent: indent, quoteDepth: quoteDepth)
        case .thematicBreak:
            appendParagraph([MarkdownRun(text: "────────────")], to: output,
                            color: theme.border, indent: indent, quoteDepth: quoteDepth, marker: marker)
        }
    }

    private func appendFrontMatter(_ metadata: String, sourceSpan: MarkdownSourceSpan?, to output: NSMutableAttributedString) {
        let table = NSTextTable()
        table.numberOfColumns = 1
        table.layoutAlgorithm = .fixedLayoutAlgorithm
        let panel = ReaderTableCell(
            table: table, startingRow: 0, rowSpan: 1, startingColumn: 0, columnSpan: 1
        )
        panel.setWidth(12, type: .absoluteValueType, for: .padding)
        panel.setWidth(1, type: .absoluteValueType, for: .border)
        panel.setBorderColor(theme.border)
        panel.backgroundColor = theme.codeBlock

        let paragraph = NSMutableParagraphStyle()
        paragraph.textBlocks = [panel]
        paragraph.lineSpacing = 3
        output.append(NSAttributedString(string: String(localized: "Metadata") + "\n", attributes: [
            .font: fontFamily.font(size: 11, weight: fontFamily.headingWeight),
            .foregroundColor: theme.primary,
            .paragraphStyle: paragraph
        ]))
        var attributes: [NSAttributedString.Key: Any] = [
            .font: fontFamily.codeFont(size: 12),
            .foregroundColor: theme.secondary,
            .paragraphStyle: paragraph
        ]
        if let sourceSpan {
            attributes[.markdownSourceMapping] = ReaderSourceMapping(
                span: sourceSpan, rendered: metadata, renderedStart: output.length
            )
        }
        output.append(NSAttributedString(string: metadata, attributes: attributes))
        attributes.removeValue(forKey: .markdownSourceMapping)
        output.append(NSAttributedString(string: "\n", attributes: attributes))
        let spacing = NSMutableParagraphStyle()
        spacing.minimumLineHeight = 16
        spacing.maximumLineHeight = 16
        output.append(NSAttributedString(string: "\n", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 1, weight: .regular),
            .paragraphStyle: spacing
        ]))
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
        table.collapsesBorders = true
        table.hidesEmptyCells = false
        table.setWidth(indent, type: .absoluteValueType, for: .margin, edge: .minX)

        for (rowIndex, row) in ([content.header] + content.rows).enumerated() {
            try Task.checkCancellation()
            await Task.yield()
            let isHeader = rowIndex == 0
            let font = fontFamily.font(size: fontFamily.tableSize,
                                       weight: isHeader ? fontFamily.tableHeadingWeight : nil)

            for (columnIndex, alignment) in content.columnAlignments.enumerated() {
                let cell = ReaderTableCell(
                    table: table, startingRow: rowIndex, rowSpan: 1,
                    startingColumn: columnIndex, columnSpan: 1
                )
                cell.setWidth(8, type: .absoluteValueType, for: .padding)
                cell.setWidth(0.5, type: .absoluteValueType, for: .border)
                cell.setBorderColor(theme.border)
                cell.verticalAlignment = .topAlignment
                if isHeader {
                    cell.backgroundColor = theme.inlineCode
                } else {
                    cell.backgroundColor = theme.document
                }

                let paragraph = NSMutableParagraphStyle()
                paragraph.textBlocks = [cell]
                paragraph.minimumLineHeight = font.pointSize * 1.8
                paragraph.alignment = switch alignment {
                case .left: .left
                case .center: .center
                case .right: .right
                }
                let base: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: isHeader ? theme.primary : theme.secondary,
                    .paragraphStyle: paragraph
                ]
                let contentCell = columnIndex < row.cells.count ? row.cells[columnIndex] : nil
                let runs = contentCell?.runs ?? []
                if runs.first?.style.contains(.code) == true {
                    paragraph.firstLineHeadIndent = 6
                }
                appendRuns(runs, to: output, font: font, base: base)
                // Even an empty cell needs a paragraph carrying its table block.
                var separatorAttributes = base
                if let span = contentCell?.sourceSpan {
                    separatorAttributes[.markdownSourceAnchor] = runs.isEmpty ? span.range.lowerBound : span.range.upperBound
                }
                output.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
            }
        }

        // Keep the gap after a table outside its cell layout and borders.
        let spacing = NSMutableParagraphStyle()
        spacing.minimumLineHeight = 12
        spacing.maximumLineHeight = 12
        output.append(NSAttributedString(string: "\n", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 1, weight: .regular),
            .paragraphStyle: spacing
        ]))
    }

    private func appendParagraph(
        _ runs: [MarkdownRun],
        to output: NSMutableAttributedString,
        font: NSFont? = nil,
        color: NSColor? = nil,
        indent: CGFloat,
        quoteDepth: Int,
        marker: String,
        isLiteralBlock: Bool = false,
        isHeading: Bool = false
    ) {
        let font = font ?? fontFamily.font(size: fontFamily.bodySize)
        let paragraph = NSMutableParagraphStyle()
        if isHeading {
            paragraph.paragraphSpacing = 15
            paragraph.paragraphSpacingBefore = output.length > 0 ? 18 : 0
            paragraph.minimumLineHeight = font.pointSize * 1.25
        } else if isLiteralBlock {
            paragraph.minimumLineHeight = font.pointSize * 1.7
        } else {
            paragraph.paragraphSpacing = marker.isEmpty ? 13 : 4
            paragraph.minimumLineHeight = font.pointSize * 1.8
        }
        paragraph.headIndent = indent
        let markerWidth = (marker.trimmingCharacters(in: .whitespacesAndNewlines) as NSString)
            .size(withAttributes: [.font: font]).width
        paragraph.firstLineHeadIndent = marker.isEmpty ? indent : indent - max(20, markerWidth + 4)
        paragraph.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
        paragraph.defaultTabInterval = 32
        if !isLiteralBlock, quoteDepth == 0, runs.first?.style.contains(.code) == true {
            if marker.isEmpty {
                paragraph.firstLineHeadIndent += 6
            } else {
                paragraph.tabStops = [NSTextTab(textAlignment: .left, location: indent + 6)]
            }
        }
        if isLiteralBlock {
            let block = ReaderCodeBlock()
            block.setContentWidth(100, type: .percentageValueType)
            block.backgroundColor = theme.codeBlock
            block.setWidth(14, type: .absoluteValueType, for: .padding)
            block.setWidth(1, type: .absoluteValueType, for: .border)
            block.setBorderColor(theme.border)
            paragraph.textBlocks = [block]
        }

        var base: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color ?? theme.secondary,
            .paragraphStyle: paragraph
        ]
        if isLiteralBlock {
            base[.readerCodeBlock] = true
        }
        if isHeading {
            base[.kern] = (fontFamily.isProportional ? -0.015 : -0.035) * font.pointSize
        }
        let prefix = marker + (quoteDepth > 0 ? "│ " : "")
        var prefixAttributes = base
        prefixAttributes[.foregroundColor] = theme.accent
        output.append(NSAttributedString(string: prefix, attributes: prefixAttributes))
        appendRuns(runs, to: output, font: font, base: base, usesInlineCodeBackground: !isLiteralBlock)
        if runs.last?.text.hasSuffix("\n") != true || runs.last?.destination != nil {
            output.append(NSAttributedString(string: "\n", attributes: base))
        }
        if isLiteralBlock {
            let spacing = NSMutableParagraphStyle()
            spacing.minimumLineHeight = 18
            spacing.maximumLineHeight = 18
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
            if let span = run.sourceSpan {
                attributes[.markdownSourceMapping] = ReaderSourceMapping(
                    span: span, rendered: run.text, renderedStart: output.length
                )
            }
            var runFont = font
            if run.style.contains(.code), usesInlineCodeBackground {
                runFont = fontFamily.codeFont(size: font.pointSize * 0.9)
                attributes[.kern] = 0
            }
            if run.style.contains(.strong) {
                runFont = NSFontManager.shared.convert(runFont, toHaveTrait: .boldFontMask)
            }
            if run.style.contains(.emphasis) {
                runFont = NSFontManager.shared.convert(runFont, toHaveTrait: .italicFontMask)
            }
            attributes[.font] = runFont
            if run.style.contains(.strong) {
                attributes[.foregroundColor] = theme.primary
            }
            if run.style.contains(.code) {
                attributes[.foregroundColor] = theme.accent
            }
            if run.style.contains(.code), usesInlineCodeBackground {
                attributes[.backgroundColor] = theme.inlineCode
                attributes[.readerInlineCode] = theme.inlineCode
            }
            if let destination = run.destination {
                if let url = ReaderLinkPolicy.allowedURL(destination) {
                    attributes[.link] = url
                    attributes[.foregroundColor] = theme.accent
                    attributes[.toolTip] = destination
                } else {
                    appendText(run.text, attributes: attributes, to: output)
                    if index + 1 == runs.count || runs[index + 1].destination != destination {
                        let label = " (\(destination))"
                        var destinationAttributes = base
                        if let span = run.linkSpan {
                            destinationAttributes[.markdownSourceMapping] = ReaderSourceMapping(
                                span: span, rendered: label, renderedStart: output.length
                            )
                        }
                        output.append(NSAttributedString(string: label, attributes: destinationAttributes))
                    }
                    continue
                }
            }
            appendText(run.text, attributes: attributes, to: output)
        }
    }

    private func appendText(_ text: String, attributes: [NSAttributedString.Key: Any],
                            to output: NSMutableAttributedString) {
        let isInlineCode = attributes[.readerInlineCode] != nil && !text.isEmpty
        if isInlineCode, output.length > 0 {
            let string = output.string as NSString
            let previous = string.rangeOfComposedCharacterSequence(at: output.length - 1)
            let character = string.substring(with: previous)
            if !character.contains(where: { $0.isNewline || $0 == "\t" }) {
                let continuesCode = output.attribute(.readerInlineCode, at: previous.location,
                                                     effectiveRange: nil) != nil
                let kern = (output.attribute(.kern, at: previous.location, effectiveRange: nil) as? NSNumber)?
                    .doubleValue ?? 0
                output.addAttribute(.kern, value: continuesCode ? 0 : kern + 6, range: previous)
            }
        }
        output.append(NSAttributedString(string: text, attributes: attributes))
        if isInlineCode {
            // Reserve padding with text attributes so copying and source offsets stay exact.
            let last = (output.string as NSString).rangeOfComposedCharacterSequence(at: output.length - 1)
            output.addAttribute(.kern, value: 6, range: last)
        }
    }
}
