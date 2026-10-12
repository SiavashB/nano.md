import SwiftUI

struct DocumentView: View {
    @Binding var document: NanoMDDocument
    @State private var mode: Mode

    private enum Mode: String, CaseIterable {
        case read = "Read"
        case edit = "Edit"
    }

    init(document: Binding<NanoMDDocument>, isNewDocument: Bool) {
        _document = document
        _mode = State(initialValue: isNewDocument ? .edit : .read)
    }

    var body: some View {
        ZStack {
            // Keep the native editor and its undo targets alive while reading.
            MarkdownEditorView(document: $document, isActive: mode == .edit)
                .allowsHitTesting(mode == .edit)
                .accessibilityHidden(mode != .edit)

            if mode == .read {
                ReaderView(source: document.source)
            }
        }
        .frame(minWidth: 360, minHeight: 240)
        .toolbar {
            Picker("Document mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
    }
}
