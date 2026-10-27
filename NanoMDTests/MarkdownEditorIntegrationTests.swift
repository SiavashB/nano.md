import AppKit
import Observation
import SwiftUI
import Testing
@testable import NanoMD

/// Exercises the shipped representable, delegate, text storage and native undo manager.
/// setMarkedText simulates the NSTextInputClient boundary, not a real input method.
@MainActor
@Suite(.serialized)
struct MarkdownEditorIntegrationTests {
    @Test
    func typingUndoAndRedoPreserveExactSource() async throws {
        let editor = try await EditorHarness(source: "# café\r\ne\u{301} 🍎\r\n")
        defer { editor.close() }
        let original = editor.document.source
        try await editor.type("追加")
        editor.expectSource(original + "追加")
        #expect(editor.undoManager.canUndo)
        #expect(editor.publications == 1)
        #expect(editor.publicationsWithUndoEnabled == 0)

        #expect(editor.perform("undo:"))
        try await editor.waitForPublication()
        editor.expectSource(original)
        #expect(!editor.undoManager.canUndo)
        #expect(editor.undoManager.canRedo)
        #expect(editor.perform("redo:"))
        try await editor.waitForPublication()
        editor.expectSource(original + "追加")
        #expect(editor.publications == 3)
        #expect(editor.publicationsWithUndoEnabled == 0)
    }

    @Test(arguments: [false, true])
    func acceptedReloadClearsUndoEvenWhenBytesMatch(identicalBytes: Bool) async throws {
        let editor = try await EditorHarness(source: "original\n")
        defer { editor.close() }
        try await editor.type("edit")
        try await editor.type(" discardable")
        #expect(editor.perform("undo:"))
        try await editor.waitForPublication()
        #expect(editor.undoManager.canUndo)
        #expect(editor.undoManager.canRedo)
        let replacement = identicalBytes ? editor.document.source : "replacement\r\n"
        let oldIdentity = editor.document.loadIdentity
        try await editor.reload(replacement)
        #expect(editor.document.loadIdentity != oldIdentity)
        editor.expectSource(replacement)
        #expect(!editor.undoManager.canUndo)
        #expect(!editor.undoManager.canRedo)
        #expect(editor.textView.lineEnding == (identicalBytes ? "\n" : "\r\n"))

        try await editor.type("fresh")
        #expect(editor.perform("undo:"))
        try await editor.waitForPublication()
        editor.expectSource(replacement)
        #expect(!editor.undoManager.canUndo)
    }

    @Test(arguments: [false, true])
    func reloadDuringCompositionCannotPublishStaleSource(commitMarkedText: Bool) async throws {
        let editor = try await EditorHarness(source: "before ")
        defer { editor.close() }
        try await editor.type("typing")
        editor.undoManager.beginUndoGrouping()
        editor.textView.setMarkedText("仮", selectedRange: NSRange(location: 1, length: 0),
                                      replacementRange: NSRange(location: NSNotFound, length: 0))
        editor.textView.breakUndoCoalescing()
        if editor.undoManager.groupingLevel > 0 { editor.undoManager.endUndoGrouping() }
        #expect(editor.textView.hasMarkedText())
        let composingSource = editor.textView.string
        let publications = editor.publications
        try await editor.reload("accepted\r\n", whileComposing: true)
        #expect(editor.textView.hasMarkedText())
        #expect(editor.textView.string == composingSource)
        #expect(editor.document.source == "accepted\r\n")
        #expect(editor.publications == publications)

        editor.undoManager.beginUndoGrouping()
        if commitMarkedText {
            editor.textView.insertText("確定", replacementRange: NSRange(location: NSNotFound, length: 0))
        }
        editor.textView.unmarkText()
        editor.textView.breakUndoCoalescing()
        if editor.undoManager.groupingLevel > 0 { editor.undoManager.endUndoGrouping() }
        try await editor.waitUntil { editor.textView.string == "accepted\r\n" }
        editor.expectSource("accepted\r\n")
        #expect(editor.publications == publications)
        #expect(!editor.undoManager.canUndo)
        #expect(!editor.undoManager.canRedo)
        try await editor.type("new")
        #expect(editor.perform("undo:"))
        try await editor.waitForPublication()
        editor.expectSource("accepted\r\n")
    }

    @Test
    func modeTransitionsRetainNativeStateAndCancelHiddenFocus() async throws {
        let editor = try await EditorHarness(source: String(repeating: "line of source\n", count: 200))
        defer { editor.close() }
        try await editor.type("edit")
        let textView = try #require(editor.textView)
        textView.setSelectedRange(NSRange(location: 40, length: 4))
        editor.scrollView.contentView.scroll(to: NSPoint(x: 0, y: 100))
        let selection = textView.selectedRange()
        let origin = editor.scrollView.contentView.bounds.origin
        #expect(origin.y > 0)
        let source = editor.document.source
        let publications = editor.publications
        try await editor.setActive(false)
        #expect(editor.window.firstResponder !== textView)
        #expect(editor.navigation.editor === textView)
        #expect(textView.selectedRange() == selection)
        #expect(editor.scrollView.contentView.bounds.origin == origin)
        #expect(editor.undoManager.canUndo)
        try await editor.setActive(true)
        #expect(editor.window.firstResponder === textView)
        #expect(textView.selectedRange() == selection)
        #expect(editor.scrollView.contentView.bounds.origin == origin)
        editor.expectSource(source)
        #expect(editor.publications == publications)

        // Queue activation, then hide before the main-actor activation task can run.
        let coordinator = try #require(textView.delegate as? MarkdownEditorView.Coordinator)
        coordinator.updateActivation(false, request: nil, textView: textView)
        coordinator.updateActivation(true, request: nil, textView: textView)
        let pendingActivation = coordinator.activationTask
        try await editor.setActive(false)
        await pendingActivation?.value
        // A new queued turn must also reject hidden views, even if activation is requested.
        coordinator.updateActivation(true, request: nil, textView: textView)
        await coordinator.activationTask?.value
        #expect(editor.window.firstResponder !== textView)
        coordinator.updateActivation(false, request: nil, textView: textView)
        try await editor.setActive(true)
        #expect(editor.perform("undo:"))
        try await editor.waitForPublication()
        #expect(editor.document.source == String(repeating: "line of source\n", count: 200))
    }

    @Test
    func documentsHaveIndependentSourceAndUndoHistory() async throws {
        let first = try await EditorHarness(source: "first ")
        let second = try await EditorHarness(source: "second ")
        defer { first.close(); second.close() }
        try await first.type("A")
        try await second.type("B")
        #expect(first.perform("undo:"))
        try await first.waitForPublication()
        first.expectSource("first ")
        second.expectSource("second B")
        #expect(second.undoManager.canUndo)
        #expect(second.perform("undo:"))
        try await second.waitForPublication()
        second.expectSource("second ")
        #expect(first.perform("redo:"))
        try await first.waitForPublication()
        first.expectSource("first A")
        try await first.reload("first replacement")
        #expect(!first.undoManager.canUndo)
        #expect(second.undoManager.canRedo)
        #expect(second.perform("redo:"))
        try await second.waitForPublication()
        second.expectSource("second B")
    }
}

@MainActor
private final class EditorHarness {
    let state: EditorTestState
    var document: NanoMDDocument { state.document }
    var publications: Int { state.publications }
    var publicationsWithUndoEnabled: Int { state.publicationsWithUndoEnabled }
    let undoManager: UndoManager
    let navigation = DocumentNavigation()
    let window: NSWindow
    private var host: NSHostingView<EditorTestRoot>?

    private(set) var textView: MarkdownEditorView.SourceTextView!

    // Initialized only after the production view has attached.
    private(set) var scrollView: NSScrollView!

    init(source: String) async throws {
        state = EditorTestState(document: try NanoMDDocument(file: FileWrapper(regularFileWithContents: Data(source.utf8))))
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                          styleMask: [.titled], backing: .buffered, defer: false)
        undoManager = try #require(window.undoManager)
        window.isReleasedWhenClosed = false
        // Each type call represents one native editing event, independent of test scheduling.
        undoManager.groupsByEvent = false
        let host = NSHostingView(rootView: EditorTestRoot(state: state, navigation: navigation, undoManager: undoManager))
        self.host = host
        window.contentView = host
        do {
            try await attach(host)
        } catch {
            close()
            throw error
        }
    }

    private func attach(_ host: NSHostingView<EditorTestRoot>) async throws {
        window.makeKeyAndOrderFront(nil)
        host.layoutSubtreeIfNeeded()
        try await waitUntil { self.navigation.editor?.window === self.window }
        textView = try #require(navigation.editor as? MarkdownEditorView.SourceTextView)
        scrollView = try #require(textView.enclosingScrollView)
        try await waitUntil {
            (self.textView.delegate as? MarkdownEditorView.Coordinator)?.undoManager === self.undoManager
        }
        window.makeFirstResponder(nil)
        window.makeFirstResponder(textView)
        try await waitUntil { self.window.firstResponder === self.navigation.editor }
    }

    func perform(_ action: String) -> Bool {
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(textView)
        return textView.tryToPerform(Selector(action), with: nil)
    }

    func type(_ text: String) async throws {
        let textView = try #require(navigation.editor)
        textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))
        undoManager.beginUndoGrouping()
        textView.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        textView.breakUndoCoalescing()
        undoManager.endUndoGrouping()
        try await waitForBindingUpdate()
    }

    func reload(_ source: String, whileComposing: Bool = false) async throws {
        state.document = try NanoMDDocument(file: FileWrapper(regularFileWithContents: Data(source.utf8)))
        host?.layoutSubtreeIfNeeded()
        if whileComposing {
            try await waitForBindingUpdate()
        } else {
            try await waitUntil { self.navigation.editor?.string == source && !self.undoManager.canUndo }
        }
    }

    func setActive(_ value: Bool) async throws {
        state.active = value
        host?.layoutSubtreeIfNeeded()
        try await waitUntil {
            self.scrollView.isHidden == !value &&
                ((self.window.firstResponder === self.navigation.editor) == value)
        }
    }

    func expectSource(_ source: String, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(document.source.utf8.elementsEqual(source.utf8), sourceLocation: sourceLocation)
        #expect(navigation.editor?.string.utf8.elementsEqual(source.utf8) == true, sourceLocation: sourceLocation)
    }

    func waitForBindingUpdate(sourceLocation: SourceLocation = #_sourceLocation) async throws {
        try await waitUntil(sourceLocation: sourceLocation) {
            guard let coordinator = self.navigation.editor?.delegate as? MarkdownEditorView.Coordinator else { return false }
            return coordinator.document.wrappedValue.source.utf8.elementsEqual(self.document.source.utf8)
        }
    }

    func waitForPublication(sourceLocation: SourceLocation = #_sourceLocation) async throws {
        try await waitUntil(sourceLocation: sourceLocation) {
            self.navigation.editor?.string.utf8.elementsEqual(self.document.source.utf8) == true
        }
    }

    func waitUntil(sourceLocation: SourceLocation = #_sourceLocation, _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(3)
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
            host?.layoutSubtreeIfNeeded()
        }
        try #require(condition(), "Native editor lifecycle did not reach the expected state", sourceLocation: sourceLocation)
    }

    func close() {
        if let coordinator = navigation.editor?.delegate as? MarkdownEditorView.Coordinator,
           let scrollView {
            MarkdownEditorView.dismantleNSView(scrollView, coordinator: coordinator)
        }
        window.contentView = nil
        host = nil
        window.close()
    }
}

@MainActor
@Observable
private final class EditorTestState {
    var document: NanoMDDocument
    var active = true
    var publications = 0
    var publicationsWithUndoEnabled = 0

    init(document: NanoMDDocument) { self.document = document }
}

@MainActor
private struct EditorTestRoot: View {
    let state: EditorTestState
    let navigation: DocumentNavigation
    let undoManager: UndoManager

    var body: some View {
        // Observe document replacement/publication as the real FileDocument host does.
        let _ = state.document
        MarkdownEditorView(document: Binding(get: { state.document }, set: {
            state.publications += 1
            if undoManager.isUndoRegistrationEnabled { state.publicationsWithUndoEnabled += 1 }
            state.document = $0
        }), isActive: state.active, theme: .linenLight, entryRequest: nil, navigation: navigation)
    }
}
