import AppKit
import SwiftUI

struct DocumentCommands: Commands {
    @FocusedValue(\.documentModeAction) private var documentModeAction
    @FocusedValue(\.documentFindAction) private var documentFindAction
    @Binding var appearancePreference: String

    var body: some Commands {
        CommandGroup(after: .textEditing) {
            Menu("Find") {
                Button("Find…") { documentFindAction?.perform(.showFindInterface) }
                    .keyboardShortcut("f", modifiers: .command)
                Button("Find Next") { documentFindAction?.perform(.nextMatch) }
                    .keyboardShortcut("g", modifiers: .command)
                Button("Find Previous") { documentFindAction?.perform(.previousMatch) }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
                Button("Use Selection for Find") { documentFindAction?.perform(.setSearchString) }
                    .keyboardShortcut("e", modifiers: .command)
            }
            .disabled(documentFindAction == nil)
        }
        CommandGroup(after: .toolbar) {
            // Register the shortcut only here, so native menu dispatch consumes it
            // before text input, even when the editor is the first responder.
            Button(documentModeAction?.title ?? "Toggle Read/Edit") {
                documentModeAction?.perform()
            }
            .keyboardShortcut("r", modifiers: .control)
            .buttonRepeatBehavior(.disabled)
            .disabled(documentModeAction == nil)

            Menu("Appearance") {
                AppearancePicker(preference: $appearancePreference)
                    .pickerStyle(.inline)
            }
        }
    }
}

struct DocumentModeAction {
    let title: String
    let perform: () -> Void
}

struct DocumentFindAction {
    let perform: (NSTextFinder.Action) -> Void
}

extension FocusedValues {
    var documentFindAction: DocumentFindAction? {
        get { self[DocumentFindActionKey.self] }
        set { self[DocumentFindActionKey.self] = newValue }
    }

    private struct DocumentFindActionKey: FocusedValueKey {
        typealias Value = DocumentFindAction
    }

    var documentModeAction: DocumentModeAction? {
        get { self[DocumentModeActionKey.self] }
        set { self[DocumentModeActionKey.self] = newValue }
    }

    private struct DocumentModeActionKey: FocusedValueKey {
        typealias Value = DocumentModeAction
    }
}
