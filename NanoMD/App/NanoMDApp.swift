import SwiftUI

@main
struct NanoMDApp: App {
    var body: some Scene {
        DocumentGroup(viewing: NanoMDDocument.self) { file in
            ReaderView(source: file.document.source)
                .focusedSceneValue(\.hasOpenDocument, true)
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            ReaderCommands()
        }
    }
}
