import SwiftUI

struct DocumentView: View {
    @Binding var document: NanoMDDocument
    @Binding var appearancePreference: String
    let filename: String
    let systemColorScheme: ColorScheme
    @State private var mode: Mode
    @State private var isFeedbackHovered = false
    @State private var navigation = DocumentNavigation()
    @State private var editorEntry: EditorEntryRequest?

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
    private var modeAction: DocumentModeAction {
        DocumentModeAction(title: mode == .read ? "Edit" : "Read") {
            switchMode(to: mode == .read ? .edit : .read)
        }
    }

    private func switchMode(to destination: Mode) {
        guard destination != mode else { return }
        if destination == .edit {
            beginEditing(at: navigation.entryPoint(for: document.source))
        } else {
            mode = .read
        }
    }

    private func beginEditing(at point: EditorEntryPoint?) {
        guard mode == .read else { return }
        editorEntry = point.map { EditorEntryRequest(loadIdentity: document.loadIdentity, point: $0) }
        mode = .edit
    }

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
            .padding(.vertical, 8)
            .foregroundStyle(Color(nsColor: theme.headerText))
            .background(Color(nsColor: theme.header))

            rule
            ZStack {
                // Keep the native editor and its undo targets alive while reading.
                MarkdownEditorView(document: $document, isActive: mode == .edit, theme: theme, entryRequest: editorEntry)
                    .allowsHitTesting(mode == .edit)
                    .accessibilityHidden(mode != .edit)

                if mode == .read {
                    ReaderView(source: document.source, theme: theme, navigation: navigation) { point in
                        guard navigation.matches(document.source) else { return }
                        beginEditing(at: point)
                    }
                }
            }
            rule
            footer
        }
        .background(Color(nsColor: theme.document))
        .overlay(Rectangle().strokeBorder(Color(nsColor: theme.border), lineWidth: 1))
        .padding(EdgeInsets(top: 2, leading: 12, bottom: 12, trailing: 12))
        .background(Color(nsColor: theme.surrounding))
        .frame(minWidth: 360, minHeight: 240)
        .preferredColorScheme(appearance.colorScheme)
        .tint(Color(nsColor: theme.accent))
        .focusedSceneValue(\.documentModeAction, modeAction)
        .toolbar(removing: .title)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Document mode", selection: Binding(get: { mode }, set: { switchMode(to: $0) })) {
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

    private var footer: some View {
        HStack(spacing: 12) {
            modeShortcut
            Spacer(minLength: 0)
            feedbackLink
        }
        .font(.system(size: 11, design: .monospaced))
        .lineLimit(1)
        .foregroundStyle(Color(nsColor: theme.secondary))
        .padding(.horizontal, 17)
        .padding(.vertical, 4)
        .background(Color(nsColor: theme.surrounding))
    }

    @ViewBuilder
    private var feedbackLink: some View {
        if let destination = URL(string: "https://nano.thirdeyeds.com/feedback") {
            Link(destination: destination) {
                Text("Feedback")
                    .underline(isFeedbackHovered)
                    .foregroundStyle(Color(nsColor: theme.accent))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Send feedback")
            .help("Open feedback options in your browser")
            .fixedSize()
            .onHover { isFeedbackHovered = $0 }
        }
    }

    private var modeShortcut: some View {
        Button(action: modeAction.perform) {
            shortcutLabel("^R", title: modeAction.title)
        }
        .accessibilityLabel("Switch to \(modeAction.title) mode")
        .help("Switch to \(modeAction.title) mode (Control+R)")
        .font(.system(size: 12, design: .monospaced))
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.disabled)
        .fixedSize()
    }

    private func shortcutLabel(_ key: String, title: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(key)
                .padding(.vertical, 1)
                .foregroundStyle(Color(nsColor: theme.document))
                .background(Color(nsColor: theme.accent))
            Text(title)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
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
