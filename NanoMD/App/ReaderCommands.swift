import AppKit
import SwiftUI

struct ReaderCommands: Commands {
    @FocusedValue(\.hasOpenDocument) private var hasOpenDocument

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}

        CommandGroup(replacing: .saveItem) {
            Button("Close") {
                NSApp.sendAction(#selector(NSWindow.performClose(_:)), to: nil, from: nil)
            }
            .keyboardShortcut("w")
            .disabled(hasOpenDocument != true)
        }
    }
}

extension FocusedValues {
    var hasOpenDocument: Bool? {
        get { self[OpenDocumentKey.self] }
        set { self[OpenDocumentKey.self] = newValue }
    }

    private struct OpenDocumentKey: FocusedValueKey {
        typealias Value = Bool
    }
}
