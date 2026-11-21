import Foundation

nonisolated final class CPlusPlusHighlighter: CHighlighter {
    override class var fenceTags: [String] { ["c++", "cpp", "cxx"] }

    override func languageToken(depth: Int) -> Kind? {
        if let prefix = ["R\"", "u8R\"", "uR\"", "UR\"", "LR\""].first(where: { remaining.hasPrefix($0) }) {
            let opener = remaining.dropFirst(prefix.count).prefix(17)
            if let paren = opener.firstIndex(of: "(") {
                let delimiter = opener[..<paren]
                if delimiter.allSatisfy({ !$0.isWhitespace && $0 != ")" && $0 != "\\" && $0.isASCII }) {
                    remaining = remaining[remaining.index(after: paren)...]
                    if let end = remaining.range(of: ")" + delimiter + "\"", options: .literal) {
                        remaining = remaining[end.upperBound...]
                    } else {
                        toEnd()
                    }
                    return .quotedText
                }
            }
        }
        return super.languageToken(depth: depth)
    }
}
