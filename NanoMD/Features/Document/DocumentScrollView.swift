import AppKit

/// Keep AppKit's finder and highlighting, but host its controls over the document header.
final class DocumentScrollView: NSScrollView {
    private weak var navigation: DocumentNavigation?
    private var nativeFindBar: NSView?
    private var focusTask: Task<Void, Never>?

    init(navigation: DocumentNavigation) {
        self.navigation = navigation
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var findBarView: NSView? {
        get { nativeFindBar }
        set {
            if newValue !== nativeFindBar, navigation?.findBarView === nativeFindBar {
                navigation?.findBarView = nil
            }
            nativeFindBar = newValue
            publishFindBar()
        }
    }

    override var isFindBarVisible: Bool {
        get { super.isFindBarVisible }
        set {
            let changed = super.isFindBarVisible != newValue
            if changed {
                super.isFindBarVisible = newValue
            }
            publishFindBar()
            if changed {
                focusTask?.cancel()
                if !newValue { restoreDocumentFocus() }
            }
        }
    }

    override func findBarViewDidChangeHeight() {
        publishFindBar()
    }

    override func tile() {
        super.tile()
        // AppKit also sizes its Find view during scroll-view layout.
        // Its header host owns that geometry once the view has moved there.
        (nativeFindBar?.superview as? FindBarHost)?.layoutFindBar()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil { isFindBarVisible = false }
    }

    private func restoreDocumentFocus() {
        focusTask = Task { @MainActor [weak self] in
            await Task.yield()
            guard !Task.isCancelled, let self, !self.isFindBarVisible,
                  let textView = self.documentView as? NSTextView,
                  !textView.isHiddenOrHasHiddenAncestor,
                  let window = self.window else { return }
            window.makeFirstResponder(textView)
        }
    }

    private func publishFindBar() {
        guard let navigation else { return }
        if isFindBarVisible, let nativeFindBar {
            // The finder first publishes its view before assigning its final height.
            if nativeFindBar.frame.height > 0 {
                navigation.findBarHeight = nativeFindBar.frame.height
            }
            navigation.findBarView = nativeFindBar
        } else if navigation.findBarView === nativeFindBar {
            navigation.findBarView = nil
        }
    }
}
