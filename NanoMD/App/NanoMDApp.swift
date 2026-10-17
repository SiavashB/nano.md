import Foundation
import SwiftUI

@main
struct NanoMDApp: App {
    @AppStorage(AppearanceMode.preferenceKey) private var themePreference = AppearanceMode.system.rawValue

    init() {
        // Use AppKit's keep-changes confirmation for this app's documents,
        // including closing them as part of quitting after an autosave.
        UserDefaults.standard.set(true, forKey: "NSCloseAlwaysConfirmsChanges")
    }

    var body: some Scene {
        DocumentGroup(newDocument: NanoMDDocument()) { file in
            DocumentView(document: file.$document, isNewDocument: file.fileURL == nil,
                         filename: file.fileURL?.lastPathComponent ?? "Untitled",
                         appearancePreference: $themePreference)
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(after: .toolbar) {
                Menu("Appearance") {
                    AppearancePicker(preference: $themePreference)
                        .pickerStyle(.inline)
                }
            }
        }
    }
}
