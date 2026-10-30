import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class DefaultMarkdownApplication: NSObject, NSApplicationDelegate, ObservableObject {
    @Published private(set) var isChangingDefault = false

    private static let offerHandledPreferenceKey = "hasHandledDefaultMarkdownAppOffer"
    private var hasFinishedLaunching = false
    private var hasConsideredLaunchOffer = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        hasFinishedLaunching = true
        considerLaunchOffer()
    }

    func applicationDidUpdate(_ notification: Notification) {
        considerLaunchOffer()
    }

    func makeDefault() {
        guard !isChangingDefault else { return }
        rememberOfferHandled()
        if isDefaultApplication {
            showMessage("nano.md is already your default Markdown app.")
            return
        }

        isChangingDefault = true
        Task { @MainActor in
            defer { isChangingDefault = false }
            do {
                try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: .markdown)
                if !isDefaultApplication {
                    showMessage("The default Markdown app wasn’t changed.",
                                detail: "You can try again from the nano.md menu or choose nano.md in Finder’s Get Info → Open with → Change All.")
                }
            } catch {
                let error = error as NSError
                if isUserCancellation(error) { return }
                showMessage("Couldn’t change the default Markdown app.",
                            detail: "\(error.localizedDescription)\n\nYou can try again from the nano.md menu or choose nano.md in Finder’s Get Info → Open with → Change All.")
            }
        }
    }

    private func isUserCancellation(_ error: NSError) -> Bool {
        if (error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError)
            || (error.domain == NSOSStatusErrorDomain && error.code == -128) {
            return true
        }
        // Launch Services can wrap userCanceledErr in a Cocoa file error.
        guard let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError else { return false }
        return isUserCancellation(underlyingError)
    }

    private var isDefaultApplication: Bool {
        guard let identifier = Bundle.main.bundleIdentifier,
              let applicationURL = NSWorkspace.shared.urlForApplication(toOpen: UTType.markdown) else { return false }
        return Bundle(url: applicationURL)?.bundleIdentifier == identifier
    }

    private var canPresentLaunchOffer: Bool {
        NSApp.isActive && NSApp.modalWindow == nil
            && !NSApp.windows.contains { $0.attachedSheet != nil }
    }

    private func considerLaunchOffer() {
        guard hasFinishedLaunching, !hasConsideredLaunchOffer,
              !isChangingDefault, canPresentLaunchOffer else { return }
        hasConsideredLaunchOffer = true

        // Hosted regression tests must not be interrupted by onboarding dialogs.
        let environment = ProcessInfo.processInfo.environment
        guard environment["XCTestConfigurationFilePath"] == nil,
              environment["XCTestBundlePath"] == nil,
              NSClassFromString("XCTestCase") == nil else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            // Let native document/open/save panels finish before presenting an offer.
            guard canPresentLaunchOffer else {
                hasConsideredLaunchOffer = false
                return
            }
            offerIfNeeded()
        }
    }

    private func offerIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.offerHandledPreferenceKey) else { return }
        rememberOfferHandled()
        guard !isDefaultApplication else { return }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Make nano.md your default Markdown app?"
        alert.informativeText = "Open .md and .markdown files with nano.md when you double-click them in Finder. You can make this change later from the nano.md menu."
        alert.addButton(withTitle: "Make Default")
        alert.addButton(withTitle: "Not Now").keyEquivalent = "\u{1b}"
        if alert.runModal() == .alertFirstButtonReturn {
            makeDefault()
        }
    }

    private func rememberOfferHandled() {
        hasConsideredLaunchOffer = true
        UserDefaults.standard.set(true, forKey: Self.offerHandledPreferenceKey)
    }

    private func showMessage(_ message: String, detail: String = "") {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = message
        alert.informativeText = detail
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
