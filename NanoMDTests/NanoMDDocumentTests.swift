import Foundation
import Testing
@testable import NanoMD

struct NanoMDDocumentTests {
    @Test
    func newDocumentsUseEmptyUTF8WithoutBOMAndLF() {
        var document = NanoMDDocument()
        #expect(document.source.isEmpty)
        #expect(!document.hasUTF8ByteOrderMark)
        #expect(document.lineEnding == "\n")
        #expect(document.fileWrapper().regularFileContents == Data())

        document.source = "# New\n\nText\n"
        #expect(document.fileWrapper().regularFileContents == Data("# New\n\nText\n".utf8))
    }

    @Test(arguments: [
        "", "\n", "# Heading\n\nParagraph\n", "  leading\tand trailing  ",
        "one\r\ntwo\r\n\r\n", "one\rtwo\r", "one\r\ntwo\nthree\rfour\n",
        "é / e\u{301} / 👩🏽‍💻 / 中文 / العربية\n", "a\u{0000}b\n"
    ], [false, true])
    func roundTripsExactBytes(source: String, hasBOM: Bool) throws {
        let bytes = (hasBOM ? Data([0xEF, 0xBB, 0xBF]) : Data()) + Data(source.utf8)
        let document = try NanoMDDocument(file: FileWrapper(regularFileWithContents: bytes))

        #expect(Data(document.source.utf8) == Data(source.utf8))
        #expect(document.hasUTF8ByteOrderMark == hasBOM)
        #expect(document.fileWrapper().regularFileContents == bytes)
    }

    @Test(arguments: [
        ("no line ending", "\n"), ("first\r\nsecond\n", "\r\n"),
        ("first\rsecond\r\n", "\r"), ("first\nsecond\r\n", "\n"),
        ("\r\n", "\r\n")
    ])
    func choosesFirstLoadedLineEnding(fixture: (String, String)) throws {
        let document = try NanoMDDocument(file: FileWrapper(regularFileWithContents: Data(fixture.0.utf8)))
        #expect(document.lineEnding == fixture.1)
    }

    @Test
    func editedSourceKeepsBOMAndUnicodeRepresentation() throws {
        let original = Data([0xEF, 0xBB, 0xBF]) + Data("name: café\r\n".utf8)
        var document = try NanoMDDocument(file: FileWrapper(regularFileWithContents: original))
        let identity = document.loadIdentity
        document.source = "name: cafe\u{301}\r\n\tchanged  \n"
        let expected = Data([0xEF, 0xBB, 0xBF]) + Data("name: cafe\u{301}\r\n\tchanged  \n".utf8)

        #expect(document.fileWrapper().regularFileContents == expected)
        #expect(document.loadIdentity == identity)
        #expect(document.lineEnding == "\r\n")
    }

    @Test(arguments: [
        Data([0xFF]), Data([0xC3]), Data([0xC0, 0xAF]),
        Data([0xED, 0xA0, 0x80]), Data([0xEF, 0xBB, 0xBF, 0xFF]),
        Data([0xFF, 0xFE, 0x41, 0x00])
    ])
    func rejectsInvalidUTF8(bytes: Data) {
        #expect(throws: (any Error).self) {
            try NanoMDDocument(file: FileWrapper(regularFileWithContents: bytes))
        }
    }

    @Test
    func rejectsDirectoriesAndSymbolicLinks() {
        #expect(throws: (any Error).self) {
            try NanoMDDocument(file: FileWrapper(directoryWithFileWrappers: [:]))
        }
        #expect(throws: (any Error).self) {
            try NanoMDDocument(file: FileWrapper(symbolicLinkWithDestinationURL: URL(fileURLWithPath: "/unused.md")))
        }
    }

    @Test
    func acceptedReloadGetsNewIdentityEvenForIdenticalBytes() throws {
        let file = FileWrapper(regularFileWithContents: Data("unchanged\n".utf8))
        let first = try NanoMDDocument(file: file)
        let reloaded = try NanoMDDocument(file: file)
        #expect(first.loadIdentity != reloaded.loadIdentity)
        #expect(first.fileWrapper().regularFileContents == reloaded.fileWrapper().regularFileContents)
    }
}
