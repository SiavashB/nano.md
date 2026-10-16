import Foundation

/// Recognizes a leading YAML mapping without interpreting or rewriting its values.
nonisolated struct MarkdownFrontMatter {
    let metadata: String
    let body: String

    init?(_ source: String) {
        var lines = source.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        guard lines.first == "---" else { return nil }
        lines.removeFirst()

        guard let closingIndex = lines.firstIndex(where: { $0 == "---" || $0 == "..." }) else {
            return nil
        }
        let header = lines[..<closingIndex]
        // Requiring a mapping field leaves ordinary leading thematic breaks as Markdown.
        guard header.contains(where: Self.isMappingField) else { return nil }

        metadata = header.joined(separator: "\n")
        let bodyIndex = lines.index(after: closingIndex)
        body = bodyIndex < lines.endIndex ? String(source[lines[bodyIndex].startIndex...]) : ""
    }

    private static func isMappingField(_ line: Substring) -> Bool {
        guard let colon = line.firstIndex(of: ":"), colon > line.startIndex else { return false }
        let key = line[..<colon]
        guard key.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else {
            return false
        }
        let valueStart = line.index(after: colon)
        return valueStart == line.endIndex || line[valueStart].isWhitespace
    }
}
