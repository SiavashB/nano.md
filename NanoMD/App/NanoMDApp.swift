import Foundation
import SwiftUI

@main
struct NanoMDApp: App {
    @NSApplicationDelegateAdaptor(DefaultMarkdownApplication.self) private var defaultMarkdownApplication
    @AppStorage(AppearanceMode.preferenceKey) private var themePreference = AppearanceMode.system.rawValue
    @State private var systemAppearance = SystemAppearance()
    @State private var readerFontSettings = ReaderFontSettings()

    init() {
        // Use AppKit's keep-changes confirmation for this app's documents,
        // including closing them as part of quitting after an autosave.
        UserDefaults.standard.set(true, forKey: "NSCloseAlwaysConfirmsChanges")
    }

    var body: some Scene {
        DocumentGroup(newDocument: NanoMDDocument()) { file in
            DocumentView(document: file.$document, isNewDocument: file.fileURL == nil,
                         filename: file.fileURL?.lastPathComponent ?? "Untitled",
                         appearancePreference: $themePreference,
                         systemColorScheme: systemAppearance.colorScheme, readerFont: readerFontSettings.value)
        }
        .defaultSize(width: 800, height: 600)
        .defaultLaunchBehavior(defaultMarkdownApplication.shouldSuppressAutomaticDocumentLaunch ? .suppressed : .automatic)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Make Default for Markdown…") {
                    defaultMarkdownApplication.makeDefault()
                }
                .disabled(defaultMarkdownApplication.isChangingDefault)
            }
            DocumentCommands(appearancePreference: $themePreference)
            CommandGroup(after: .toolbar) {
                Menu("Reader Font") {
                    Button("Choose Font…") {
                        readerFontSettings.showFontPanel()
                    }
                    Button("Use Default Font") {
                        readerFontSettings.useDefaultFont()
                    }
                }
            }
        }
    }
}
