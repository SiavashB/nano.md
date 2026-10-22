import Testing
@testable import NanoMD

struct MarkdownParserTests {
    @Test
    func emptyDocumentIsValid() async throws {
        let content = try await MarkdownParser().parse("")
        #expect(content.blocks.isEmpty)
    }

    @Test
    func preservesHeadingInlineStylesAndLinkDestination() async throws {
        let content = try await MarkdownParser().parse("# **Strong** *soft* `code` [web](https://example.com)\n")
        #expect(content.blocks.count == 1)
        guard case let .heading(level, runs) = try #require(content.blocks.first) else {
            Issue.record("Expected a heading")
            return
        }
        #expect(level == 1)
        #expect(runs.map(\.text) == ["Strong", " ", "soft", " ", "code", " ", "web"])
        try #require(runs.count == 7)
        #expect(runs[0].style.contains(.strong))
        #expect(runs[2].style.contains(.emphasis))
        #expect(runs[4].style.contains(.code))
        #expect(runs[6].destination == "https://example.com")
    }

    @Test
    func distinguishesSoftAndHardLineBreaks() async throws {
        let content = try await MarkdownParser().parse("soft\nwrap  \nhard\n")
        guard case let .paragraph(runs) = try #require(content.blocks.first) else {
            Issue.record("Expected a paragraph with soft and hard breaks")
            return
        }
        #expect(runs.map(\.text).joined() == "soft wrap\u{2028}hard")
    }

    @Test
    func retainsListStartAndTaskMarkers() async throws {
        let content = try await MarkdownParser().parse("3. first\n4. second\n\n- [x] done\n- [ ] todo\n")
        #expect(content.blocks.count == 2)
        guard content.blocks.count == 2,
              case let .list(start, ordered) = content.blocks[0],
              case let .list(taskStart, tasks) = content.blocks[1] else {
            Issue.record("Expected ordered and task lists")
            return
        }
        #expect(start == 3)
        #expect(ordered.count == 2)
        #expect(taskStart == nil)
        #expect(tasks.map(\.checkbox) == ["[x]", "[ ]"])
    }

    @Test
    func parsesQuotesCodeAndThematicBreaks() async throws {
        let content = try await MarkdownParser().parse(
            "> quoted\n\n```swift\n\tlet x = \"<tag>\"  \n```\n\n---\n"
        )
        guard content.blocks.count == 3,
              case let .quote(children) = content.blocks[0],
              case let .paragraph(runs) = try #require(children.first),
              case let .code(code) = content.blocks[1],
              case .thematicBreak = content.blocks[2] else {
            Issue.record("Expected a quote, literal code, and thematic break")
            return
        }
        #expect(runs.map(\.text).joined() == "quoted")
        #expect(code == "\tlet x = \"<tag>\"  \n")
    }

    @Test
    func parsesTableAlignmentCellsAndInlineFormatting() async throws {
        let content = try await MarkdownParser().parse(
            "| Left | Center | Right |\n| :--- | :---: | ---: |\n| **bold** | middle | |\n"
        )
        guard case let .table(table) = try #require(content.blocks.first) else {
            Issue.record("Expected a table")
            return
        }
        #expect(table.columnAlignments == [.left, .center, .right])
        #expect(table.header.cells.map { $0.map(\.text).joined() } == ["Left", "Center", "Right"])
        let row = try #require(table.rows.first)
        #expect(row.cells.map { $0.map(\.text).joined() } == ["bold", "middle", ""])
        #expect(try #require(row.cells.first?.first).style.contains(.strong))
    }

    @Test
    func htmlRemainsLiteralAndImagesBecomeUnlinkedPlaceholders() async throws {
        let html = "<script>\nalert('example')\n</script>\n"
        let block = try await MarkdownParser().parse(html)
        guard case let .literal(text) = try #require(block.blocks.first) else {
            Issue.record("Expected literal HTML")
            return
        }
        #expect(text == html)

        let inline = try await MarkdownParser().parse("<span>text</span> ![Alt](https://example.com/image.png)\n")
        guard case let .paragraph(runs) = try #require(inline.blocks.first) else {
            Issue.record("Expected inline literal text and image placeholder")
            return
        }
        #expect(runs.map(\.text).joined() == "<span>text</span> [Alt (https://example.com/image.png)]")
        #expect(runs.allSatisfy { $0.destination == nil })
        #expect(runs.first?.style.contains(.code) == true)
    }

    @Test
    func separatesFrontMatterFromBodyWithoutPromotingMetadataToHeadings() async throws {
        let content = try await MarkdownParser().parse("---\nname: skill\n---\n# Body\n")
        guard content.blocks.count == 2,
              case let .frontMatter(metadata) = content.blocks[0],
              case let .heading(level, runs) = content.blocks[1] else {
            Issue.record("Expected metadata followed by the body heading")
            return
        }
        #expect(metadata == "name: skill")
        #expect(level == 1)
        #expect(runs.map(\.text).joined() == "Body")
    }

    @Test
    func sourceLimitCountsUTF8BytesAndAcceptsExactlyOneMiB() async throws {
        let parser = MarkdownParser()
        let source = String(repeating: "é", count: 524_288)
        let accepted = try await parser.parse(source)
        #expect(accepted.blocks.count == 1)
        await #expect(throws: MarkdownRenderingError.tooLarge) {
            try await parser.parse(source + "a")
        }
    }

    @Test
    func nestingLimitAcceptsDepth64AndRejectsDepth65() async throws {
        let parser = MarkdownParser()
        let accepted = try await parser.parse(String(repeating: "> ", count: 62) + "text\n")
        #expect(accepted.blocks.count == 1)
        await #expect(throws: MarkdownRenderingError.tooComplex) {
            try await parser.parse(String(repeating: "> ", count: 63) + "text\n")
        }
    }

    @Test
    func nodeLimitAccepts50000AndRejects50001() async throws {
        let parser = MarkdownParser()
        // Document + 24,999 paragraph/text pairs + one thematic break = 50,000 nodes.
        let accepted = try await parser.parse(String(repeating: "p\n\n", count: 24_999) + "---\n")
        #expect(accepted.blocks.count == 25_000)
        await #expect(throws: MarkdownRenderingError.tooComplex) {
            try await parser.parse(String(repeating: "p\n\n", count: 25_000))
        }
    }
}
