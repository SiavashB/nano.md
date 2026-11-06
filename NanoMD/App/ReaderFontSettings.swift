import AppKit
import Observation

@Observable
final class ReaderFontSettings: NSObject, NSFontChanging, NSWindowDelegate {
    private static let preferenceKey = "readerFontPostScriptName"
    private(set) var value: ReaderFont
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let name = defaults.string(forKey: Self.preferenceKey), NSFont(name: name, size: 15) != nil {
            value = ReaderFont(postScriptName: name)
        } else {
            value = .defaultFont
        }
        super.init()
    }

    func showFontPanel() {
        let manager = NSFontManager.shared
        manager.target = self
        manager.action = #selector(changeFont(_:))
        manager.setSelectedFont(value.font(size: value.bodySize), isMultiple: false)
        let panel = NSFontPanel.shared
        panel.delegate = self
        panel.title = String(localized: "Reader Font")
        manager.orderFrontFontPanel(nil)
    }

    func useDefaultFont() {
        value = .defaultFont
        defaults.removeObject(forKey: Self.preferenceKey)
        if NSFontManager.shared.target as? ReaderFontSettings === self {
            NSFontManager.shared.setSelectedFont(value.font(size: value.bodySize), isMultiple: false)
        }
    }

    func changeFont(_ sender: NSFontManager?) {
        guard let sender else { return }
        let font = sender.convert(value.font(size: value.bodySize))
        value = ReaderFont(postScriptName: font.fontName)
        defaults.set(font.fontName, forKey: Self.preferenceKey)
        sender.setSelectedFont(value.font(size: value.bodySize), isMultiple: false)
    }

    func validModesForFontPanel(_ fontPanel: NSFontPanel) -> NSFontPanel.ModeMask {
        // This preference chooses a face; Markdown still controls sizes and decoration.
        [.face, .collection]
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSFontPanel === NSFontPanel.shared,
              NSFontManager.shared.target as? ReaderFontSettings === self else { return }
        NSFontManager.shared.target = nil
    }
}
