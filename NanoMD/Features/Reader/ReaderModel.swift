import AppKit
import Observation

@Observable
final class ReaderModel {
    enum State {
        case loading
        case ready(NSAttributedString, source: String)
        case source(String)
    }

    private(set) var state: State = .loading
    private let parser = MarkdownParser()
    private var revision = UUID()
    private var renderRevision = UUID()
    private var content: MarkdownContent?
    private var sourceSnapshot = ""
    private var theme: AppTheme

    init(theme: AppTheme) {
        self.theme = theme
    }

    func load(_ source: String) async {
        guard !Task.isCancelled else { return }
        let request = UUID()
        revision = request
        renderRevision = UUID()
        content = nil
        state = .loading

        do {
            let content = try await parser.parse(source)
            try Task.checkCancellation()
            guard revision == request else { return }
            self.content = content
            sourceSnapshot = source
            await renderCurrentContent()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, revision == request else { return }
            state = .source(error.localizedDescription)
        }
    }

    func restyle(_ theme: AppTheme) async {
        guard !Task.isCancelled else { return }
        self.theme = theme
        await renderCurrentContent()
    }

    private func renderCurrentContent() async {
        guard let content else { return }
        let source = sourceSnapshot
        let request = UUID()
        renderRevision = request
        do {
            let text = try await MarkdownTextRenderer(theme: theme).render(content)
            try Task.checkCancellation()
            guard renderRevision == request else { return }
            state = .ready(text, source: source)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, renderRevision == request else { return }
            state = .source(error.localizedDescription)
        }
    }
}
