import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class SystemAppearance {
    private(set) var colorScheme: ColorScheme
    @ObservationIgnored private var observation: NSKeyValueObservation?

    init() {
        colorScheme = Self.currentColorScheme
        observation = NSApplication.shared.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.colorScheme = Self.currentColorScheme
            }
        }
    }

    private static var currentColorScheme: ColorScheme {
        NSApplication.shared.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .dark : .light
    }
}

nonisolated enum AppearanceMode: String, CaseIterable, Sendable {
    case dark
    case light
    case system

    static let preferenceKey = "appearanceTheme"

    init(preference: String) {
        switch preference {
        case "linenLight": self = .light
        case "nanoDark": self = .dark
        default: self = Self(rawValue: preference) ?? .system
        }
    }

    var name: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    func theme(for colorScheme: ColorScheme) -> AppTheme {
        switch self {
        case .system: colorScheme == .dark ? .nanoDark : .linenLight
        case .light: .linenLight
        case .dark: .nanoDark
        }
    }
}

nonisolated enum AppTheme: Equatable, Sendable {
    case nanoDark
    case linenLight

    var surrounding: NSColor { color(0x202724, 0xEAE8DE) }
    var document: NSColor { color(0x18201C, 0xF7F5EE) }
    var primary: NSColor { color(0xEDF3EE, 0x25352C) }
    var secondary: NSColor { color(0xB0C0B5, 0x536258) }
    var accent: NSColor { color(0x86D89F, 0x326647) }
    var border: NSColor { color(0x43564A, 0xB8C5B8) }
    var inlineCode: NSColor { color(0x26332B, 0xE4EBE0) }
    var codeBlock: NSColor { color(0x111914, 0xEEF1E8) }
    var header: NSColor { color(0x86D89F, 0xD2E6D5) }
    var headerText: NSColor { color(0x202724, 0x25352C) }

    private func color(_ dark: UInt32, _ light: UInt32) -> NSColor {
        let hex = self == .nanoDark ? dark : light
        return NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
                       green: CGFloat((hex >> 8) & 255) / 255,
                       blue: CGFloat(hex & 255) / 255, alpha: 1)
    }

    @MainActor
    func apply(to scrollView: NSScrollView) {
        let appearance = NSAppearance(named: self == .nanoDark ? .darkAqua : .aqua)
        scrollView.appearance = appearance
        scrollView.backgroundColor = document
        guard let textView = scrollView.documentView as? NSTextView else { return }
        textView.appearance = appearance
        textView.backgroundColor = document
        textView.insertionPointColor = accent
        textView.selectedTextAttributes = [.backgroundColor: accent, .foregroundColor: document]
        textView.linkTextAttributes = [.foregroundColor: accent, .underlineStyle: NSUnderlineStyle.single.rawValue]
    }
}

struct AppearancePicker: View {
    @Binding var preference: String

    var body: some View {
        Picker("Appearance", selection: Binding(
            get: { AppearanceMode(preference: preference) },
            set: { preference = $0.rawValue }
        )) {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                Text(mode.name).tag(mode)
            }
        }
    }
}
