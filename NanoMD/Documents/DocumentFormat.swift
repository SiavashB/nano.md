import Foundation
import UniformTypeIdentifiers

nonisolated enum DocumentFormat: Equatable {
    case markdown
    case plainText
    case code(String)

    private static let languagesByExtension = [
        "swift": "swift", "py": "python", "java": "java", "rb": "ruby", "cs": "csharp",
        "js": "javascript", "mjs": "javascript", "cjs": "javascript", "kt": "kotlin", "kts": "kotlin",
        "ts": "typescript", "mts": "typescript", "cts": "typescript", "tsx": "tsx", "css": "css",
        "c": "c", "h": "c", "cc": "cpp", "cpp": "cpp", "cxx": "cpp", "hh": "cpp", "hpp": "cpp", "hxx": "cpp",
        "sh": "bash", "bash": "bash", "html": "html", "htm": "html", "xml": "xml", "xhtml": "xml"
    ]

    static let contentTypes: [UTType] = {
        // Markdown is the default for new documents. Keep the generic text type last.
        var types: [UTType] = [.markdown]
        for ext in languagesByExtension.keys.sorted() {
            if let type = UTType(filenameExtension: ext, conformingTo: .text), type != .plainText, !types.contains(type) {
                types.append(type)
            }
        }
        return types + [.plainText]
    }()

    init(fileURL: URL?, contentType: UTType) {
        let ext = fileURL?.pathExtension ?? ""
        let suffix = (ext.isEmpty ? contentType.preferredFilenameExtension ?? "" : ext).lowercased()
        switch suffix {
        case "md", "markdown": self = .markdown
        case "txt": self = .plainText
        default:
            if let language = Self.languagesByExtension[suffix] {
                self = .code(language)
            } else {
                self = contentType.conforms(to: .markdown) ? .markdown : .plainText
            }
        }
    }

    var language: String? {
        if case let .code(language) = self { return language }
        return nil
    }
}
