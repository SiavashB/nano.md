import AppKit

/// Document navigation owns force-click, including lookup requests queued during a mode switch.
class DocumentTextView: NSTextView {
    override func pressureChange(with event: NSEvent) {}

    override func quickLook(with event: NSEvent) {}

    override func quickLookPreviewItems(_ sender: Any?) {}

    override func showDefinition(for attributedString: NSAttributedString?, at textBaselineOrigin: NSPoint) {}

    override func showDefinition(
        for attributedString: NSAttributedString?,
        range targetRange: NSRange,
        options: [NSView.DefinitionOptionKey: Any]?,
        baselineOriginProvider originProvider: ((NSRange) -> NSPoint)?
    ) {}
}
