import AppKit

struct EditorEntryPoint {
    let sourceOffset: Int
    let viewportOffset: CGFloat?
}

struct EditorEntryRequest {
    let id = UUID()
    let loadIdentity: UUID
    let point: EditorEntryPoint
}

/// Reads native selection and scrolling only when switching modes; no per-scroll view updates.
final class DocumentNavigation {
    weak var reader: ReaderInteractionTextView?

    func matches(_ source: String) -> Bool {
        reader?.sourceSnapshot.utf8.elementsEqual(source.utf8) == true
    }

    func entryPoint(for source: String) -> EditorEntryPoint? {
        guard matches(source) else { return nil }
        return reader?.entryPoint()
    }
}
