import SwiftUI

struct ReaderView: View {
    let source: String
    @State private var model = ReaderModel()

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView("Rendering Markdown…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .ready(text):
                MarkdownTextView(text: text)
            case let .source(reason):
                VStack(spacing: 0) {
                    Text(reason)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                    MarkdownSourceView(source: source)
                }
            }
        }
        .frame(minWidth: 360, minHeight: 240)
        .task(id: SourceIdentity(source: source)) {
            await model.load(source)
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
    ReaderView(source: "# NanoMD\n\nA lightweight **Markdown** reader.\n")
}
