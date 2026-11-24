nonisolated final class XMLHighlighter: MarkupHighlighter {
    override class var fenceTags: [String] { ["xml", "xhtml"] }

    override class func startsTagName(_ character: Character) -> Bool {
        // XML 1.0 NameStartChar includes namespace colons and names from multiple scripts.
        switch character.unicodeScalars.first!.value {
        case 0x3A, 0x41...0x5A, 0x5F, 0x61...0x7A, 0xC0...0xD6, 0xD8...0xF6,
             0xF8...0x2FF, 0x370...0x37D, 0x37F...0x1FFF, 0x200C...0x200D,
             0x2070...0x218F, 0x2C00...0x2FEF, 0x3001...0xD7FF, 0xF900...0xFDCF,
             0xFDF0...0xFFFD, 0x10000...0xEFFFF: true
        default: false
        }
    }

    override class func continuesReferenceName(_ character: Character) -> Bool {
        switch character.unicodeScalars.first!.value {
        case 0x2D, 0x2E, 0x30...0x39, 0xB7, 0x300...0x36F, 0x203F...0x2040: true
        default: startsTagName(character)
        }
    }

    override func scanSpecialMarkup() -> Bool {
        if take("<![CDATA[", as: .symbol) {
            scanLiteralBody(until: "]]>")
            return true
        }
        guard take("<?", as: .symbol) else { return false }
        let target = remaining.prefix { !Self.isMarkupSpace($0) && $0 != "?" }
        consume(to: target.endIndex, as: .keyword)
        if target == "xml" {
            scanAttributes(endingWith: "?>")
        } else {
            scanLiteralBody(until: "?>")
        }
        return true
    }

    private func scanLiteralBody(until delimiter: String) {
        if let closing = remaining.firstRange(of: delimiter) {
            consume(to: closing.lowerBound)
            consume(to: closing.upperBound, as: .symbol)
        } else {
            consume(to: remaining.endIndex)
        }
    }
}
