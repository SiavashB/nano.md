import SwiftUI

struct DocumentCommands: Commands {
    @FocusedValue(\.documentModeAction) private var documentModeAction
    @Binding var appearancePreference: String

    var body: some Commands {
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

extension FocusedValues {
    var documentModeAction: DocumentModeAction? {
        get { self[DocumentModeActionKey.self] }
        set { self[DocumentModeActionKey.self] = newValue }
    }

    private struct DocumentModeActionKey: FocusedValueKey {
        typealias Value = DocumentModeAction
    }
}
