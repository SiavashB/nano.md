import AppKit
import SwiftUI

struct FindBarView: NSViewRepresentable {
    let findBar: NSView
    let focusFindBar: () -> Void

    func makeNSView(context: Context) -> FindBarHost {
        let host = FindBarHost()
        // The green header stays light in both document themes.
        host.appearance = NSAppearance(named: .aqua)
        host.focusFindBar = focusFindBar
        host.installFindBar(findBar)
        return host
    }

    func updateNSView(_ host: FindBarHost, context: Context) {
        host.focusFindBar = focusFindBar
        guard findBar.superview !== host else { return }
        host.installFindBar(findBar)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: FindBarHost, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 520, height: proposal.height ?? findBar.frame.height)
    }
}

final class FindBarHost: NSView {
    var focusFindBar: (() -> Void)?
    private var focusTask: Task<Void, Never>?

    func installFindBar(_ findBar: NSView) {
        subviews.forEach { $0.removeFromSuperview() }
        findBar.translatesAutoresizingMaskIntoConstraints = true
        findBar.frame = bounds
        findBar.autoresizingMask = [.width, .height]
        addSubview(findBar)
        scheduleFocus()
    }

    override func layout() {
        super.layout()
        layoutFindBar()
    }

    func layoutFindBar() {
        for view in subviews {
            view.frame = bounds
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleFocus()
    }

    func scheduleFocus() {
        focusTask?.cancel()
        guard window != nil else { return }
        focusTask = Task { @MainActor [weak self] in
            // AppKit cannot focus its field until SwiftUI attaches the header host.
            await Task.yield()
            guard !Task.isCancelled, let self, self.window != nil else { return }
            self.focusFindBar?()
            self.needsLayout = true
            self.layoutSubtreeIfNeeded()
        }
    }
}
