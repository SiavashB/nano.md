import SwiftUI

@main
struct NanoMDApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: NanoMDDocument()) { file in
            DocumentView(document: file.$document, isNewDocument: file.fileURL == nil)
        }
        .defaultSize(width: 800, height: 600)
    }
}
