import AppKit

nonisolated struct ReaderFont: Equatable, Sendable {
    let postScriptName: String

    @MainActor
    static var defaultFont: ReaderFont {
        ReaderFont(postScriptName: "Monaco")
    }

    @MainActor
    var isProportional: Bool { !font(size: 15).isFixedPitch }

    @MainActor
    var bodySize: CGFloat { isProportional ? 15 : 13 }

    @MainActor
    var tableSize: CGFloat { isProportional ? 14 : 13 }

    @MainActor
    var headingWeight: NSFont.Weight { isProportional ? .medium : .bold }

    @MainActor
    var tableHeadingWeight: NSFont.Weight { isProportional ? .medium : .semibold }

    @MainActor
    func headingSize(level: Int) -> CGFloat {
        let sizes: [CGFloat] = isProportional ? [28, 24, 20, 18, 16, 15] : [28, 24, 20, 17, 15, 13]
        return sizes[min(max(level, 1), 6) - 1]
    }

    @MainActor
    func font(size: CGFloat, weight: NSFont.Weight? = nil) -> NSFont {
        let face = NSFont(name: postScriptName, size: size)
            ?? NSFont(name: "Monaco", size: size)
            ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        guard let weight else { return face }
        var traits = face.fontDescriptor.object(forKey: .traits) as? [NSFontDescriptor.TraitKey: Any] ?? [:]
        traits[.weight] = weight.rawValue
        let descriptor = NSFontDescriptor(fontAttributes: [
            .family: face.familyName ?? face.fontName,
            .traits: traits
        ])
        return NSFont(descriptor: descriptor, size: size) ?? face
    }

    @MainActor
    func codeFont(size: CGFloat) -> NSFont {
        .monospacedSystemFont(ofSize: size, weight: .regular)
    }
}
