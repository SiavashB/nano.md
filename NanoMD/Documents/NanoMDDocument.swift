import Foundation
import SwiftUI
import UniformTypeIdentifiers

nonisolated struct NanoMDDocument: FileDocument {
    let source: String
    let hasUTF8ByteOrderMark: Bool

    static let readableContentTypes: [UTType] = [.markdown]
    static let writableContentTypes: [UTType] = []

    init(configuration: ReadConfiguration) throws {
        guard configuration.file.isRegularFile,
              let data = configuration.file.regularFileContents else {
            throw MarkdownDocumentError.notRegularFile
        }

        hasUTF8ByteOrderMark = data.starts(with: [0xEF, 0xBB, 0xBF])
        let contents = hasUTF8ByteOrderMark ? data.dropFirst(3) : data[...]

        guard let source = String(data: contents, encoding: .utf8) else {
            throw MarkdownDocumentError.invalidUTF8
        }

        self.source = source
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        throw CocoaError(.fileWriteNoPermission)
    }
}

private nonisolated enum MarkdownDocumentError: LocalizedError {
    case notRegularFile
    case invalidUTF8

    var errorDescription: String? {
        switch self {
        case .notRegularFile:
            String(localized: "The document is not a regular text file.")
        case .invalidUTF8:
            String(localized: "The document is not valid UTF-8 text.")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notRegularFile:
            String(localized: "Open a Markdown file with a .md or .markdown extension.")
        case .invalidUTF8:
            String(localized: "Save a copy of the document using UTF-8 encoding, then open that copy.")
        }
    }
}
