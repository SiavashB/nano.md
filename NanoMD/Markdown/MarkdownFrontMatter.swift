import Foundation

/// Recognizes a subset of leading YAML mapping keys without interpreting their values.
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
        if let quote = line.first, quote == "\"" || quote == "'" {
            var remainder = line.dropFirst()
            while let character = remainder.first {
                remainder.removeFirst()
                if quote == "\"", character == "\\" {
                    guard !remainder.isEmpty else { return false }
                    remainder.removeFirst()
                } else if character == quote {
                    if quote == "'", remainder.first == quote {
                        remainder.removeFirst()
                    } else {
                        return isMappingSeparator(remainder.drop(while: { $0 == " " || $0 == "\t" }))
                    }
                }
            }
            return false
        }

        guard let colon = line.firstIndex(of: ":"), colon > line.startIndex else { return false }
        let key = line[..<colon]
        guard key.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }) else {
            return false
        }
        return isMappingSeparator(line[colon...])
    }

    private static func isMappingSeparator(_ line: Substring) -> Bool {
        guard line.first == ":" else { return false }
        let valueStart = line.index(after: line.startIndex)
        return valueStart == line.endIndex || line[valueStart].isWhitespace
    }
}
