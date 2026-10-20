import SwiftUI

struct DocumentView: View {
    @Binding var document: NanoMDDocument
    @Binding var appearancePreference: String
    let filename: String
    let systemColorScheme: ColorScheme
    @State private var mode: Mode

    private enum Mode: String, CaseIterable {
        case read = "Read"
        case edit = "Edit"

        var iconName: String {
            switch self {
            case .read: "DocumentPreview"
            case .edit: "DocumentEdit"
            }
        }
    }

    init(document: Binding<NanoMDDocument>, isNewDocument: Bool, filename: String,
         appearancePreference: Binding<String>, systemColorScheme: ColorScheme) {
        _document = document
        _appearancePreference = appearancePreference
        self.filename = filename
        self.systemColorScheme = systemColorScheme
        _mode = State(initialValue: isNewDocument ? .edit : .read)
    }

    private var appearance: AppearanceMode { AppearanceMode(preference: appearancePreference) }
    private var theme: AppTheme { appearance.theme(for: systemColorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Text("nano.md").bold()
                Spacer(minLength: 0)
                Text(filename).truncationMode(.middle)
            }
            .font(.system(size: 12, design: .monospaced))
            .lineLimit(1)
            .padding(.horizontal, 17)
            .padding(.vertical, 12)
            .foregroundStyle(Color(nsColor: theme.headerText))
            .background(Color(nsColor: theme.header))

            rule
            ZStack {
                // Keep the native editor and its undo targets alive while reading.
                MarkdownEditorView(document: $document, isActive: mode == .edit, theme: theme)
                    .allowsHitTesting(mode == .edit)
                    .accessibilityHidden(mode != .edit)

                if mode == .read {
                    ReaderView(source: document.source, theme: theme)
                }
            }
            rule
            HStack {
                Text(filename).truncationMode(.middle)
                Spacer(minLength: 12)
                Text("UTF-8")
            }
            .font(.system(size: 11, design: .monospaced))
            .lineLimit(1)
            .foregroundStyle(Color(nsColor: theme.secondary))
            .padding(.horizontal, 17)
            .padding(.vertical, 10)
            .background(Color(nsColor: theme.surrounding))
        }
        .background(Color(nsColor: theme.document))
        .overlay(Rectangle().strokeBorder(Color(nsColor: theme.border), lineWidth: 1))
        .padding(12)
        .background(Color(nsColor: theme.surrounding))
        .frame(minWidth: 360, minHeight: 240)
        .preferredColorScheme(appearance.colorScheme)
        .tint(Color(nsColor: theme.accent))
        .toolbar(removing: .title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Document mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, image: mode.iconName)
                            .labelStyle(.iconOnly)
                            .help(mode.rawValue)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            appearanceToolbarItem
        }
    }

    @ToolbarContentBuilder
    private var appearanceToolbarItem: some ToolbarContent {
        if #available(macOS 26.0, *) {
            ToolbarItem(placement: .primaryAction) {
                appearanceControl
                    .glassEffect(.regular, in: .capsule)
                    .padding(.trailing, 4)
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .primaryAction) {
                appearanceControl
                    .padding(.trailing, 4)
            }
        }
    }

    private var appearanceControl: some View {
        AppearancePicker(preference: $appearancePreference)
            .labelStyle(.iconOnly)
            .pickerStyle(.segmented)
            .fixedSize()
            .help("Appearance: \(appearance.name)")
    }

    private var rule: some View {
        Color(nsColor: theme.border).frame(height: 1)
    }
}
