import AppKit

class ReaderInteractionTextView: DocumentTextView {
    var sourceSnapshot = ""
    var displaysSource = false
    var onEdit: ((EditorEntryPoint) -> Void)?
    private(set) var handledForceClick = false

    func enableForceClick() {
        // After recognition fails, ordinary selection needs only stage-one pressure.
        pressureConfiguration = NSPressureConfiguration(pressureBehavior: .primaryClick)
        let recognizer = ReaderForceClickRecognizer(target: self, action: #selector(forceClickRecognized(_:)))
        // Keep stage two available during incidental motion; the recognizer owns drag tolerance.
        recognizer.pressureConfiguration = NSPressureConfiguration(pressureBehavior: .primaryDeepDrag)
        // NSTextView starts a tracking loop on mouse-down. Keep it out of that loop until
        // this press becomes a normal click/drag, or consume the whole force-click sequence.
        recognizer.delaysPrimaryMouseButtonEvents = true
        addGestureRecognizer(recognizer)
    }

    func entryPoint(at point: NSPoint? = nil) -> EditorEntryPoint? {
        let index: Int
        if let point {
            index = characterIndexForInsertion(at: point)
        } else if let selection = selectedRanges.map(\.rangeValue)
            .filter({ $0.length > 0 }).min(by: { $0.location < $1.location }) {
            index = selection.location
        } else {
            guard visibleRect.minY > 0.5 else { return nil }
            index = characterIndexForInsertion(at: NSPoint(
                x: textContainerInset.width, y: visibleRect.minY + 1
            ))
        }
        guard index != NSNotFound else { return nil }
        let sourceOffset: Int
        if displaysSource {
            sourceOffset = min(index, sourceSnapshot.utf16.count)
        } else if let storage = textStorage, storage.length > 0 {
            let location = min(index, storage.length - 1)
            if let mapping = storage.attribute(.markdownSourceMapping, at: location, effectiveRange: nil)
                as? ReaderSourceMapping {
                sourceOffset = mapping.sourceOffset(at: index)
            } else if let anchor = storage.attribute(.markdownSourceAnchor, at: location, effectiveRange: nil) as? Int {
                sourceOffset = anchor
            } else {
                return nil
            }
        } else {
            sourceOffset = 0
        }
        let rect = characterRect(at: min(index, string.utf16.count))
        let viewportOffset = rect.flatMap { rect -> CGFloat? in
            rect.maxY > visibleRect.minY && rect.minY < visibleRect.maxY ? rect.minY - visibleRect.minY : nil
        }
        return EditorEntryPoint(sourceOffset: sourceOffset, viewportOffset: viewportOffset)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    fileprivate func beginPrimaryClick() {
        handledForceClick = false
    }

    @objc private func forceClickRecognized(_ recognizer: ReaderForceClickRecognizer) {
        // Target/action runs after recognition; don't unmount the reader during event arbitration.
        guard recognizer.state == .recognized, !handledForceClick,
              let entry = recognizer.entryPoint else { return }
        handledForceClick = true
        onEdit?(entry)
    }
}

private final class ReaderForceClickRecognizer: NSGestureRecognizer {
    private static let movementTolerance: CGFloat = 5
    private(set) var entryPoint: EditorEntryPoint?
    private var mouseDownLocation: NSPoint?

    override func reset() {
        super.reset()
        entryPoint = nil
        mouseDownLocation = nil
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        (view as? ReaderInteractionTextView)?.beginPrimaryClick()
        guard event.associatedEventsMask.contains(.pressure),
              !event.modifierFlags.contains(.control) else {
            state = .failed
            return
        }
        mouseDownLocation = event.locationInWindow
    }

    override func pressureChange(with event: NSEvent) {
        super.pressureChange(with: event)
        guard state == .possible, let mouseDownLocation else { return }
        guard !exceedsMovementTolerance(at: event.locationInWindow) else {
            state = .failed
            return
        }
        guard event.stage >= 2 else { return }
        guard let reader = view as? ReaderInteractionTextView,
              let entry = reader.entryPoint(at: reader.convert(mouseDownLocation, from: nil)) else {
            state = .failed
            return
        }
        entryPoint = entry
        state = .recognized
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        // A gradual press can move slightly. Hand off only after an actual drag from its origin.
        if state == .possible, exceedsMovementTolerance(at: event.locationInWindow) {
            state = .failed
        }
    }

    private func exceedsMovementTolerance(at location: NSPoint) -> Bool {
        guard let mouseDownLocation else { return false }
        let dx = location.x - mouseDownLocation.x
        let dy = location.y - mouseDownLocation.y
        return dx * dx + dy * dy > Self.movementTolerance * Self.movementTolerance
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        if state == .possible { state = .failed }
    }

    override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        if state == .possible { state = .failed }
    }

    override func otherMouseDown(with event: NSEvent) {
        super.otherMouseDown(with: event)
        if state == .possible { state = .failed }
    }

    // Native recognizers wait for the same click/drag decision as the text view's event handlers.
    override func canBePrevented(by preventingGestureRecognizer: NSGestureRecognizer) -> Bool { false }

    override func shouldBeRequiredToFail(by otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        otherGestureRecognizer.view === view || super.shouldBeRequiredToFail(by: otherGestureRecognizer)
    }
}

extension NSTextView {
    /// NSTextInputClient provides geometry without switching the editor out of TextKit 2.
    func characterRect(at offset: Int) -> NSRect? {
        guard let window else { return nil }
        let screenRect = firstRect(forCharacterRange: NSRange(location: offset, length: 0), actualRange: nil)
        guard screenRect.height > 0, screenRect.origin.y.isFinite else { return nil }
        return convert(window.convertFromScreen(screenRect), from: nil)
    }
}
