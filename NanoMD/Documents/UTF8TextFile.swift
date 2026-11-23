import Foundation

nonisolated struct UTF8TextFile {
    let source: String
    let hasByteOrderMark: Bool

    init(_ file: FileWrapper) throws {
        guard file.isRegularFile, let data = file.regularFileContents else {
            throw TextFileError.notRegularFile
        }

        hasByteOrderMark = data.starts(with: [0xEF, 0xBB, 0xBF])
        let contents = hasByteOrderMark ? data.dropFirst(3) : data[...]
        guard let source = String(data: contents, encoding: .utf8) else {
            throw TextFileError.invalidUTF8
        }
        self.source = source
    }
}

private nonisolated enum TextFileError: LocalizedError {
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
            String(localized: "Choose a regular text file.")
        case .invalidUTF8:
            String(localized: "Save a copy of the document using UTF-8 encoding, then open that copy.")
        }
    }
}
