import SwiftUI

struct ReaderView: View {
    let source: String
    let theme: AppTheme
    let navigation: DocumentNavigation
    let onEdit: (EditorEntryPoint) -> Void
    @State private var model: ReaderModel

    init(source: String, theme: AppTheme, navigation: DocumentNavigation,
         onEdit: @escaping (EditorEntryPoint) -> Void) {
        self.source = source
        self.theme = theme
        self.navigation = navigation
        self.onEdit = onEdit
        _model = State(initialValue: ReaderModel(theme: theme))
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView("Rendering Markdown…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .ready(text, renderedSource):
                MarkdownTextView(text: text, source: renderedSource, theme: theme, navigation: navigation, onEdit: onEdit)
            case let .source(reason):
                VStack(spacing: 0) {
                    Text(reason)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(nsColor: theme.secondary))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Color(nsColor: theme.border).frame(height: 1)
                    MarkdownSourceView(source: source, theme: theme, navigation: navigation, onEdit: onEdit)
                }
            }
        }
        .font(.system(size: 14, design: .monospaced))
        .foregroundStyle(Color(nsColor: theme.secondary))
        .background(Color(nsColor: theme.document))
        .frame(minWidth: 360, minHeight: 240)
        .task(id: SourceIdentity(source: source)) {
            await model.load(source)
        }
        .task(id: theme) {
            await model.restyle(theme)
        }
    }

    // Swift's canonical string equality must not hide a changed source representation.
    private struct SourceIdentity: Equatable {
        let source: String

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.source.utf8.elementsEqual(rhs.source.utf8)
        }
    }
}

#Preview {
    ReaderView(source: "# NanoMD\n\nA lightweight **Markdown** reader.\n", theme: .linenLight,
               navigation: DocumentNavigation(), onEdit: { _ in })
}
