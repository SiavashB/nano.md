import Foundation
import Testing
@testable import NanoMD

struct MarkdownFrontMatterTests {
    @Test(arguments: [
        "name: release-notes", "version.number: 1.2", "empty:",
        "'display name': value", "'it''s a key': value", "\"key: with colon\": value",
        "\"escaped \\\"quote\\\"\"\t: value", "ключ: значение"
    ])
    func recognizesDocumentedMappingKeys(field: String) throws {
        let result = try #require(MarkdownFrontMatter("---\n\(field)\n---\n# Body\n"))
        #expect(result.metadata == field)
        #expect(result.body == "# Body\n")
    }

    @Test(arguments: [
        "---\nordinary text\n---\n", "---\nname: value\n", " ---\nname: value\n---\n",
        "--- \nname: value\n---\n", "---\nname:value\n---\n",
        "---\n  name: value\n---\n", "---\n: value\n---\n",
        "---\n'open: value\n---\n", "---\n\"open: value\n---\n",
        "---\n\"key\"extra: value\n---\n", "---\n\"key\\\n---\n",
        "---\nname: value\n ---\n", "# Heading\n---\nname: value\n---\n"
    ])
    func leavesNonEnvelopesAsOrdinaryMarkdown(source: String) {
        #expect(MarkdownFrontMatter(source) == nil)
    }

    @Test(arguments: ["---", "..."])
    func preservesBodyBytesWhileNormalizingMetadataDisplay(closing: String) throws {
        let body = "\r\n# cafe\u{301}\r\n\ttext  \nlast\r"
        let result = try #require(MarkdownFrontMatter("---\r\nname: skill\r\nversion: 1\r\n\(closing)\r\n\(body)"))
        #expect(result.metadata == "name: skill\nversion: 1")
        #expect(Data(result.body.utf8) == Data(body.utf8))
    }

    @Test
    func keepsComplexValuesLiteralRatherThanValidatingYAML() throws {
        let header = "name: skill\ndescription: |\n  multiple lines\nmalformed: ["
        let result = try #require(MarkdownFrontMatter("---\n\(header)\n---"))
        #expect(result.metadata == header)
        #expect(result.body.isEmpty)
    }
}
