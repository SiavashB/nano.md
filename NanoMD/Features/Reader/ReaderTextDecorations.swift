import AppKit

extension NSAttributedString.Key {
    nonisolated static let readerInlineCode = Self("NanoMD.inlineCode")
    nonisolated static let readerCodeBlock = Self("NanoMD.codeBlock")
}

nonisolated final class ReaderTableCell: NSTextTableBlock {
    // The reader paints complete cell bounds in its view-background pass. Suppress
    // the glyph-background pass so antialiased borders are not painted twice.
    override func drawBackground(withFrame frameRect: NSRect, in controlView: NSView?,
                                 characterRange charRange: NSRange, layoutManager: NSLayoutManager) {}

    func drawCompleteBackground(withFrame frameRect: NSRect, in controlView: NSView,
                                characterRange charRange: NSRange, layoutManager: NSLayoutManager) {
        MainActor.preconditionIsolated()
        super.drawBackground(withFrame: frameRect, in: controlView,
                             characterRange: charRange, layoutManager: layoutManager)
    }
}

// AppKit's drawing primitives are nonisolated. The main-actor reader owns these
// instances; drawing checks that ownership without transferring layout objects.
nonisolated final class ReaderCodeBlock: NSTextBlock {
    override func drawBackground(withFrame frameRect: NSRect, in controlView: NSView?,
                                 characterRange charRange: NSRange, layoutManager: NSLayoutManager) {
        MainActor.preconditionIsolated()
        backgroundColor?.setFill()
        NSBezierPath(roundedRect: frameRect, xRadius: 2, yRadius: 2).fill()
        borderColor(for: .minX)?.setStroke()
        let border = NSBezierPath(roundedRect: frameRect.insetBy(dx: 0.5, dy: 0.5),
                                  xRadius: 1.5, yRadius: 1.5)
        border.lineWidth = 1
        border.stroke()
    }
}

nonisolated final class ReaderLayoutManager: NSLayoutManager, NSLayoutManagerDelegate {
    private var backgroundOrigin = NSPoint.zero

    override init() {
        super.init()
        delegate = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        delegate = self
    }

    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>,
                       lineFragmentUsedRect: UnsafeMutablePointer<NSRect>,
                       baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer,
                       forGlyphRange glyphRange: NSRange) -> Bool {
        MainActor.preconditionIsolated()
        guard glyphRange.length > 0, let storage = textStorage else { return false }
        let index = characterIndexForGlyph(at: glyphRange.location)
        guard index < storage.length,
              storage.attribute(.readerCodeBlock, at: index, effectiveRange: nil) as? Bool == true,
              let font = storage.attribute(.font, at: index, effectiveRange: nil) as? NSFont else { return false }

        // Center the capital-to-descender text box inside the CSS-style line height.
        // Changing the layout baseline also keeps native selection and hit testing aligned.
        baselineOffset.pointee = (lineFragmentRect.pointee.height + font.capHeight + font.descender) / 2
        return true
    }

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        MainActor.preconditionIsolated()
        let previousOrigin = backgroundOrigin
        backgroundOrigin = origin
        defer { backgroundOrigin = previousOrigin }
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }

    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<NSRect>, count rectCount: Int,
                                          forCharacterRange charRange: NSRange, color: NSColor) {
        MainActor.preconditionIsolated()
        guard let storage = textStorage, charRange.location < storage.length,
              let codeColor = storage.attribute(.readerInlineCode, at: charRange.location,
                                                 effectiveRange: nil) as? NSColor,
              codeColor.isEqual(color),
              let font = storage.attribute(.font, at: charRange.location, effectiveRange: nil) as? NSFont,
              let container = textContainers.first else {
            super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
            return
        }

        // Decorate the font's typographic box, rather than the taller paragraph line.
        // Native drawing still owns selection, Find highlights, and table backgrounds.
        for index in 0..<rectCount {
            var rect = rectArray[index]
            let point = NSPoint(x: rect.minX - backgroundOrigin.x, y: rect.midY - backgroundOrigin.y)
            let glyph = glyphIndex(for: point, in: container)
            guard glyph < numberOfGlyphs else { continue }
            let line = lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            let baseline = line.minY + location(forGlyphAt: glyph).y + backgroundOrigin.y
            rect.origin.y = baseline - font.ascender - 3
            rect.size.height = font.ascender - font.descender + 6
            rect.origin.x -= 6
            // The final character already reserves the trailing six points in layout.
            rect.size.width += index == rectCount - 1 ? 6 : 12
            NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()
        }
    }
}
