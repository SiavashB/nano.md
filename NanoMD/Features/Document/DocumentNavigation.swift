import AppKit
import Observation

struct EditorEntryPoint {
    let sourceOffset: Int
    let viewportOffset: CGFloat?
}

struct EditorEntryRequest {
    let id = UUID()
    let loadIdentity: UUID
    let point: EditorEntryPoint
}

/// Routes document commands to native views without retaining them or observing scrolling.
@Observable
final class DocumentNavigation {
    @ObservationIgnored
    weak var reader: ReaderInteractionTextView?
    @ObservationIgnored
    weak var editor: NSTextView?
    var findBarView: NSView?
    var findBarHeight: CGFloat = 32

    func performFindAction(_ action: NSTextFinder.Action, inEditor: Bool) {
        guard let textView = inEditor ? editor : reader,
              let window = textView.window,
              !textView.isHiddenOrHasHiddenAncestor else { return }
        if action == .showFindInterface {
            window.makeFirstResponder(textView)
        }
        let sender = NSMenuItem()
        sender.tag = action.rawValue
        textView.performFindPanelAction(sender)
    }

    func dismissFindInterface(inEditor: Bool) {
        let textView = inEditor ? editor : reader
        guard let scrollView = textView?.enclosingScrollView,
              scrollView.isFindBarVisible else { return }
        performFindAction(.hideFindInterface, inEditor: inEditor)
        // The find field is hosted in the header, outside the document text view.
        scrollView.window?.makeFirstResponder(nil)
    }

    func matches(_ source: String) -> Bool {
        reader?.sourceSnapshot.utf8.elementsEqual(source.utf8) == true
    }

    func entryPoint(for source: String) -> EditorEntryPoint? {
        guard matches(source) else { return nil }
        return reader?.entryPoint()
    }
}
