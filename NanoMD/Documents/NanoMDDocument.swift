import Foundation
import SwiftUI
import UniformTypeIdentifiers

nonisolated struct NanoMDDocument: FileDocument {
    var source: String
    let contentType: UTType
    let hasUTF8ByteOrderMark: Bool
    let lineEnding: String
    private let posixPermissions: Int?
    // A system reload/revert replaces this identity; ordinary edits and saves do not.
    let loadIdentity = UUID()

    static let writableContentTypes = DocumentFormat.contentTypes
    // The Open panel can classify .ts and .mts as transport streams even when they contain source.
    static let readableContentTypes = writableContentTypes + [.mpeg2TransportStream]

    init() {
        source = ""
        contentType = .markdown
        hasUTF8ByteOrderMark = false
        lineEnding = "\n"
        posixPermissions = nil
    }

    init(configuration: ReadConfiguration) throws {
        try self.init(file: configuration.file, contentType: configuration.contentType)
    }

    init(file: FileWrapper, contentType: UTType = .markdown) throws {
        if contentType.conforms(to: .mpeg2TransportStream) {
            let filename = file.preferredFilename ?? file.filename
            let ext = filename.map { ($0 as NSString).pathExtension.lowercased() } ?? contentType.preferredFilenameExtension
            guard let ext, ["ts", "mts"].contains(ext),
                  let sourceType = UTType(filenameExtension: ext, conformingTo: .text) else {
                throw CocoaError(.fileReadCorruptFile, userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "Choose a TypeScript source file with a .ts or .mts extension.")
                ])
            }
            self.contentType = sourceType
        } else {
            self.contentType = contentType
        }
        let text = try UTF8TextFile(file)
        posixPermissions = file.fileAttributes[FileAttributeKey.posixPermissions.rawValue] as? Int
        source = text.source
        hasUTF8ByteOrderMark = text.hasByteOrderMark
        lineEnding = source.first { $0 == "\r\n" || $0 == "\r" || $0 == "\n" }
            .map(String.init) ?? "\n"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let wrapper = fileWrapper()
        let key = FileAttributeKey.posixPermissions.rawValue
        if let mode = configuration.existingFile?.fileAttributes[key] as? Int ?? posixPermissions {
            wrapper.fileAttributes[key] = mode
        }
        return wrapper
    }

    func fileWrapper() -> FileWrapper {
        var data = Data()
        if hasUTF8ByteOrderMark {
            data.append(contentsOf: [0xEF, 0xBB, 0xBF])
        }
        data.append(contentsOf: source.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
