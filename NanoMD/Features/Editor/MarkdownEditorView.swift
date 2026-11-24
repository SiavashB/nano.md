import AppKit
import SwiftUI

struct MarkdownEditorView: NSViewRepresentable {
    @Binding var document: NanoMDDocument
    let isActive: Bool
    let theme: AppTheme
    let entryRequest: EditorEntryRequest?
    let navigation: DocumentNavigation
    var format: DocumentFormat = .markdown
    var onEdit: ((EditorEntryPoint) -> Void)?
    @Environment(\.undoManager) private var undoManager

    func makeCoordinator() -> Coordinator {
        Coordinator(document: $document)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = DocumentScrollView(navigation: navigation)

        let textView = SourceTextView(usingTextLayoutManager: true)
        context.coordinator.textView = textView
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isSelectable = true
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 20, height: 20)
        NativeTextViewConfiguration.apply(to: textView, in: scrollView)
        textView.string = document.source
        textView.lineEnding = document.lineEnding
        textView.compositionDidEnd = { [weak coordinator = context.coordinator, weak textView] in
            // Let the input method finish its native edit before applying an accepted reload.
            Task { @MainActor in
                guard let textView else { return }
                coordinator?.applyReload(to: textView)
                textView.applyTextTheme()
                textView.syntax?.refresh()
                coordinator?.scheduleActivation(of: textView)
            }
        }
        scrollView.documentView = textView
        navigation.editor = textView
        context.coordinator.undoManager = undoManager
        configure(textView, in: scrollView)
        textView.didAttachToWindow = { [weak coordinator = context.coordinator, weak textView] in
            guard let textView else { return }
            coordinator?.scheduleActivation(of: textView)
        }
        context.coordinator.updateActivation(isActive, request: entryRequest, textView: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SourceTextView else { return }
        let coordinator = context.coordinator
        coordinator.document = $document
        coordinator.undoManager = undoManager
        coordinator.applyReload(to: textView)
        configure(textView, in: scrollView)
        coordinator.updateActivation(isActive, request: entryRequest, textView: textView)
    }

    private func configure(_ textView: SourceTextView, in scrollView: NSScrollView) {
        let hidden = format == .markdown && !isActive
        let editable = format == .markdown || isActive
        if hidden, scrollView.window?.firstResponder === textView {
            textView.breakUndoCoalescing()
            scrollView.window?.makeFirstResponder(nil)
        }
        if textView.isEditable != editable {
            if !editable { textView.breakUndoCoalescing() }
            textView.isEditable = editable
        }
        scrollView.isHidden = hidden
        let readingSource = format != .markdown && !isActive
        if readingSource {
            textView.sourceSnapshot = document.source
            navigation.reader = textView
        } else if navigation.reader === textView {
            navigation.reader = nil
        }
        textView.displaysSource = readingSource
        textView.setReadAction(readingSource ? onEdit : nil)
        let label = switch format {
        case .markdown: String(localized: "Markdown source editor")
        case .plainText: editable ? String(localized: "Text editor") : String(localized: "Text document")
        case .code: editable ? String(localized: "Source code editor") : String(localized: "Source code")
        }
        textView.setAccessibilityLabel(label)
        theme.apply(to: scrollView)
        textView.theme = theme
        textView.format = format
        textView.applyTextTheme()
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        // The manager is document-scoped; its native text targets must not outlive the window.
        coordinator.undoManager?.removeAllActions()
        coordinator.cancelActivation()
        coordinator.undoManager = nil
        coordinator.textView?.syntax?.detach()
        coordinator.textView?.delegate = nil
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var document: Binding<NanoMDDocument>
        weak var textView: SourceTextView?
        weak var undoManager: UndoManager? {
            didSet {
                guard oldValue !== undoManager else { return }
                let center = NotificationCenter.default
                if let oldValue {
                    center.removeObserver(self, name: .NSUndoManagerDidUndoChange, object: oldValue)
                    center.removeObserver(self, name: .NSUndoManagerDidRedoChange, object: oldValue)
                }
                if let undoManager {
                    center.addObserver(self, selector: #selector(undoOrRedoDidChange),
                                       name: .NSUndoManagerDidUndoChange, object: undoManager)
                    center.addObserver(self, selector: #selector(undoOrRedoDidChange),
                                       name: .NSUndoManagerDidRedoChange, object: undoManager)
                }
            }
        }
        private var loadIdentity: UUID
        private var isApplyingReload = false
        private var isActive = false
        private var entryRequest: EditorEntryRequest?
        private var needsActivation = false
        private(set) var activationTask: Task<Void, Never>?

        init(document: Binding<NanoMDDocument>) {
            self.document = document
            loadIdentity = document.wrappedValue.loadIdentity
        }

        @objc private func undoOrRedoDidChange(_ notification: Notification) {
            // Native undo can change text storage without a textDidChange delegate callback.
            // Publish after the manager finishes; the source comparison also deduplicates
            // AppKit paths that do deliver the callback.
            guard let textView else { return }
            textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
        }

        func undoManager(for view: NSTextView) -> UndoManager? {
            undoManager
        }

        func updateActivation(_ active: Bool, request: EditorEntryRequest?, textView: SourceTextView) {
            let changed = active && (!isActive || request?.id != entryRequest?.id)
            isActive = active
            entryRequest = request
            if !active {
                cancelActivation()
            } else if changed {
                needsActivation = true
                scheduleActivation(of: textView)
            }
        }

        func cancelActivation() {
            activationTask?.cancel()
            activationTask = nil
            needsActivation = false
        }

        func scheduleActivation(of textView: SourceTextView) {
            guard needsActivation else { return }
            activationTask?.cancel()
            activationTask = Task { @MainActor [weak self, weak textView] in
                // Wait for SwiftUI to reveal the persistent editor and remove the reader.
                await Task.yield()
                guard !Task.isCancelled, let self, self.isActive,
                      let textView, let window = textView.window,
                      !textView.isHiddenOrHasHiddenAncestor, !textView.hasMarkedText() else { return }
                self.needsActivation = false
                let oldOrigin = textView.enclosingScrollView?.contentView.bounds.origin
                window.makeFirstResponder(textView)
                guard let request = self.entryRequest,
                      request.loadIdentity == self.loadIdentity,
                      request.loadIdentity == self.document.wrappedValue.loadIdentity else {
                    if let oldOrigin, let scrollView = textView.enclosingScrollView {
                        scrollView.contentView.scroll(to: oldOrigin)
                        scrollView.reflectScrolledClipView(scrollView.contentView)
                    }
                    return
                }
                let source = textView.string as NSString
                var offset = min(max(0, request.point.sourceOffset), source.length)
                if offset < source.length {
                    offset = source.rangeOfComposedCharacterSequence(at: offset).location
                }
                let selection = NSRange(location: offset, length: 0)
                textView.breakUndoCoalescing()
                textView.setSelectedRange(selection)
                textView.scrollRangeToVisible(selection)
                if let viewportOffset = request.point.viewportOffset,
                   let rect = textView.characterRect(at: offset),
                   let scrollView = textView.enclosingScrollView {
                    let maximumY = max(0, textView.bounds.height - scrollView.contentView.bounds.height)
                    let y = min(max(0, rect.minY - viewportOffset), maximumY)
                    scrollView.contentView.scroll(to: NSPoint(x: 0, y: y))
                    scrollView.reflectScrolledClipView(scrollView.contentView)
                }
            }
        }

        func applyReload(to textView: SourceTextView) {
            let value = document.wrappedValue
            guard value.loadIdentity != loadIdentity else { return }
            guard !textView.hasMarkedText() else { return }

            isApplyingReload = true
            defer { isApplyingReload = false }
            textView.breakUndoCoalescing()
            undoManager?.removeAllActions()
            loadIdentity = value.loadIdentity
            textView.lineEnding = value.lineEnding
            if !textView.string.utf8.elementsEqual(value.source.utf8) {
                textView.string = value.source
                textView.syntax?.refresh()
            }
        }

        func textDidChange(_ notification: Notification) {
            guard !isApplyingReload, let textView = notification.object as? SourceTextView else { return }
            textView.applyTextTheme()
            // The system owns conflict acceptance. Never publish an old editor over its reload.
            guard document.wrappedValue.loadIdentity == loadIdentity else {
                applyReload(to: textView)
                return
            }
            guard !document.wrappedValue.source.utf8.elementsEqual(textView.string.utf8) else { return }

            // NSTextView owns typing undo. Suppress FileDocument binding undo for this publication
            // so a second whole-document action cannot accompany the native text operation.
            undoManager?.disableUndoRegistration()
            defer { undoManager?.enableUndoRegistration() }
            document.wrappedValue.source = textView.string
        }
    }

    final class SourceTextView: ReaderInteractionTextView {
        var lineEnding = "\n"
        var compositionDidEnd: (() -> Void)?
        var didAttachToWindow: (() -> Void)?
        var theme: AppTheme = .linenLight
        var format: DocumentFormat = .markdown
        private(set) var syntax: SourceSyntaxHighlighting?
        private var appliedTextTheme: AppTheme?
        private var appliedFormat: DocumentFormat?
        private var readGesture: NSGestureRecognizer?

        func setReadAction(_ action: ((EditorEntryPoint) -> Void)?) {
            if action != nil, readGesture == nil { readGesture = enableForceClick() }
            if let readGesture, readGesture.isEnabled != (action != nil) {
                readGesture.isEnabled = action != nil
            }
            onEdit = action
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil { didAttachToWindow?() }
        }

        func applyTextTheme() {
            // Leave marked text under input-method ownership until composition finishes.
            guard !hasMarkedText(), appliedTextTheme != theme || appliedFormat != format else { return }
            let foreground = switch format {
            case .markdown: theme.secondary
            case .plainText: theme.primary
            case .code: theme.codeBlockText
            }
            textColor = foreground
            typingAttributes[.foregroundColor] = foreground
            if syntax?.language != format.language {
                syntax?.detach()
                syntax = format.language.flatMap { SourceSyntaxHighlighting(textView: self, language: $0, theme: theme) }
            } else {
                syntax?.applyTheme(theme)
            }
            appliedTextTheme = theme
            appliedFormat = format
        }

        override func insertNewline(_ sender: Any?) {
            insertText(lineEnding, replacementRange: NSRange(location: NSNotFound, length: 0))
        }

        override func insertLineBreak(_ sender: Any?) {
            insertNewline(sender)
        }

        override func unmarkText() {
            super.unmarkText()
            compositionDidEnd?()
        }

        override func paste(_ sender: Any?) {
            pasteAsPlainText(sender)
        }
    }
}
