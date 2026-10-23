import AppKit
import Testing
@testable import NanoMD

@MainActor
@Suite(.serialized)
struct DocumentFindTests {
    @Test(arguments: [false, true])
    func findBarTargetsVisibleMode(inEditor: Bool) {
        let navigation = DocumentNavigation()
        let reader = FindRecordingReader(usingTextLayoutManager: false)
        let editor = FindRecordingEditor(usingTextLayoutManager: true)
        let readerScroll = makeScrollView(reader, navigation: navigation)
        let editorScroll = makeScrollView(editor, navigation: navigation)
        let window = makeWindow()
        defer { window.close() }
        window.contentView?.addSubview(readerScroll)
        window.contentView?.addSubview(editorScroll)
        readerScroll.isHidden = inEditor
        editorScroll.isHidden = !inEditor
        navigation.reader = reader
        navigation.editor = editor

        navigation.performFindAction(.showFindInterface, inEditor: inEditor)
        navigation.performFindAction(.nextMatch, inEditor: inEditor)
        navigation.performFindAction(.previousMatch, inEditor: inEditor)
        let expected = [NSTextFinder.Action.showFindInterface.rawValue,
                        NSTextFinder.Action.nextMatch.rawValue,
                        NSTextFinder.Action.previousMatch.rawValue]
        #expect(reader.actions == (inEditor ? [] : expected))
        #expect(editor.actions == (inEditor ? expected : []))
        #expect(window.firstResponder === (inEditor ? editor : reader))

        // A stale command must never reach a hidden editor or detached reader.
        navigation.performFindAction(.showFindInterface, inEditor: !inEditor)
        readerScroll.removeFromSuperview()
        editorScroll.removeFromSuperview()
        navigation.performFindAction(.showFindInterface, inEditor: inEditor)
        #expect(reader.actions == (inEditor ? [] : expected))
        #expect(editor.actions == (inEditor ? expected : []))
    }

    @Test(arguments: [false, true])
    func nativeFindBarOpensAndDismissesWithoutChangingSource(inEditor: Bool) {
        let navigation = DocumentNavigation()
        let textView: NSTextView
        if inEditor {
            let editor = MarkdownEditorView.SourceTextView(usingTextLayoutManager: true)
            navigation.editor = editor
            textView = editor
        } else {
            let reader = ReaderInteractionTextView(usingTextLayoutManager: false)
            reader.isEditable = false
            reader.isSelectable = true
            navigation.reader = reader
            textView = reader
        }
        let source = "🍎 café\r\nSecond café\r\n"
        textView.string = source
        let scrollView = makeScrollView(textView, navigation: navigation)
        let window = makeWindow()
        defer { window.close() }
        window.contentView?.addSubview(scrollView)
        #expect(textView.usesFindBar)
        #expect(textView.isIncrementalSearchingEnabled)
        #expect(!scrollView.isFindBarVisible)

        let contentBounds = scrollView.contentView.bounds
        navigation.performFindAction(.showFindInterface, inEditor: inEditor)
        #expect(scrollView.isFindBarVisible)
        #expect(scrollView.findBarView != nil)
        #expect(navigation.findBarView === scrollView.findBarView)
        #expect(scrollView.contentView.bounds == contentBounds)
        navigation.dismissFindInterface(inEditor: inEditor)
        #expect(!scrollView.isFindBarVisible)
        #expect(navigation.findBarView == nil)
        #expect(Array(textView.string.utf8) == Array(source.utf8))
        #expect(textView.isEditable == inEditor)

        navigation.performFindAction(.showFindInterface, inEditor: inEditor)
        #expect(scrollView.isFindBarVisible)
    }

    @Test(arguments: [false, true])
    func headerFindControlsStayInsideHostAfterScrollLayout(inEditor: Bool) throws {
        let navigation = DocumentNavigation()
        let textView: NSTextView
        if inEditor {
            let editor = MarkdownEditorView.SourceTextView(usingTextLayoutManager: true)
            navigation.editor = editor
            textView = editor
        } else {
            let reader = ReaderInteractionTextView(usingTextLayoutManager: false)
            reader.isEditable = false
            reader.isSelectable = true
            navigation.reader = reader
            textView = reader
        }
        let scrollView = makeScrollView(textView, navigation: navigation)
        let window = makeWindow()
        defer { window.close() }
        window.contentView?.addSubview(scrollView)
        navigation.performFindAction(.showFindInterface, inEditor: inEditor)
        let findBar = try #require(navigation.findBarView)
        #expect(navigation.findBarHeight > 0)
        let host = FindBarHost(frame: NSRect(x: 0, y: 0, width: 520, height: navigation.findBarHeight))
        window.contentView?.addSubview(host)
        host.installFindBar(findBar)
        scrollView.tile()
        host.layoutSubtreeIfNeeded()
        #expect(findBar.frame == host.bounds)
        let searchField = try #require(findSearchField(in: findBar))
        let fieldRect = searchField.convert(searchField.bounds, to: host)
        #expect(fieldRect.minX >= 0)
        #expect(fieldRect.maxX <= host.bounds.width)
        #expect(fieldRect.minY >= 0)
        #expect(fieldRect.maxY <= host.bounds.height)

        host.frame.size.width = 360
        scrollView.tile()
        host.layoutSubtreeIfNeeded()
        #expect(findBar.frame == host.bounds)
    }

    @Test
    func commandsStayWithinTheirDocument() {
        let first = DocumentNavigation()
        let second = DocumentNavigation()
        let firstReader = FindRecordingReader(usingTextLayoutManager: false)
        let secondReader = FindRecordingReader(usingTextLayoutManager: false)
        let firstWindow = makeWindow()
        let secondWindow = makeWindow()
        defer { firstWindow.close(); secondWindow.close() }
        firstWindow.contentView?.addSubview(makeScrollView(firstReader, navigation: first))
        secondWindow.contentView?.addSubview(makeScrollView(secondReader, navigation: second))
        first.reader = firstReader
        second.reader = secondReader
        first.performFindAction(.showFindInterface, inEditor: false)
        #expect(firstReader.actions == [NSTextFinder.Action.showFindInterface.rawValue])
        #expect(secondReader.actions.isEmpty)
    }

    private func findSearchField(in view: NSView) -> NSSearchField? {
        if let field = view as? NSSearchField { return field }
        for child in view.subviews {
            if let field = findSearchField(in: child) { return field }
        }
        return nil
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        return window
    }

    private func makeScrollView(_ textView: NSTextView, navigation: DocumentNavigation) -> NSScrollView {
        let scrollView = DocumentScrollView(navigation: navigation)
        scrollView.frame = NSRect(x: 0, y: 0, width: 600, height: 400)
        NativeTextViewConfiguration.apply(to: textView, in: scrollView)
        textView.frame = scrollView.contentView.bounds
        scrollView.documentView = textView
        return scrollView
    }
}

@MainActor
private final class FindRecordingReader: ReaderInteractionTextView {
    var actions: [Int] = []

    override func performFindPanelAction(_ sender: Any?) {
        if let sender = sender as? NSMenuItem { actions.append(sender.tag) }
    }
}

@MainActor
private final class FindRecordingEditor: DocumentTextView {
    var actions: [Int] = []

    override func performFindPanelAction(_ sender: Any?) {
        if let sender = sender as? NSMenuItem { actions.append(sender.tag) }
    }
}
