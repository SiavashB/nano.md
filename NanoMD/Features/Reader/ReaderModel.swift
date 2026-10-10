import AppKit
import Observation

@Observable
final class ReaderModel {
    enum State {
        case loading
        case ready(NSAttributedString)
        case source(String)
    }

    private(set) var state: State = .loading
    private let parser = MarkdownParser()
    private var revision = UUID()

    func load(_ source: String) async {
        let request = UUID()
        revision = request
        state = .loading

        do {
            let content = try await parser.parse(source)
            try Task.checkCancellation()
            let text = try await MarkdownTextRenderer().render(content)
            try Task.checkCancellation()
            guard revision == request else { return }
            state = .ready(text)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, revision == request else { return }
            state = .source(error.localizedDescription)
        }
    }
}
