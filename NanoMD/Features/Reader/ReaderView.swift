import SwiftUI

struct ReaderView: View {
    let source: String
    let theme: AppTheme
    @State private var model: ReaderModel

    init(source: String, theme: AppTheme) {
        self.source = source
        self.theme = theme
        _model = State(initialValue: ReaderModel(theme: theme))
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView("Rendering Markdown…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .ready(text):
                MarkdownTextView(text: text, theme: theme)
            case let .source(reason):
                VStack(spacing: 0) {
                    Text(reason)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(nsColor: theme.secondary))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Color(nsColor: theme.border).frame(height: 1)
                    MarkdownSourceView(source: source, theme: theme)
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
    ReaderView(source: "# NanoMD\n\nA lightweight **Markdown** reader.\n", theme: .linenLight)
}
