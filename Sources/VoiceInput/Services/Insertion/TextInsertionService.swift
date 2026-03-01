import AppKit
import ApplicationServices
import Foundation

enum TextInsertionResult {
    case insertedDirectly
    case insertedViaPaste
    case copiedToClipboard
    case manualRequired
}

final class TextInsertionService {
    func insert(text: String, settings: SettingsStore.Snapshot) -> TextInsertionResult {
        if insertUsingAccessibility(text: text) {
            AppLogger.insertion.debug("Inserted text via Accessibility API")
            return .insertedDirectly
        }

        if settings.autoPasteEnabled, insertUsingPasteShortcut(text: text) {
            AppLogger.insertion.debug("Inserted text via paste shortcut fallback")
            return .insertedViaPaste
        }

        if settings.copyToClipboardOnFailure {
            copyToClipboard(text)
            AppLogger.insertion.debug("Copied text to clipboard fallback")
            return .copiedToClipboard
        }

        return .manualRequired
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func insertUsingAccessibility(text: String) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?

        let focusedResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusedResult == .success,
              let focusedElement,
              CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return false
        }

        let axElement = focusedElement as! AXUIElement

        let selectedTextResult = AXUIElementSetAttributeValue(
            axElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        if selectedTextResult == .success {
            return true
        }

        let valueResult = AXUIElementSetAttributeValue(
            axElement,
            kAXValueAttribute as CFString,
            text as CFTypeRef
        )

        return valueResult == .success
    }

    private func insertUsingPasteShortcut(text: String) -> Bool {
        copyToClipboard(text)

        guard let source = CGEventSource(stateID: .hidSystemState),
              let vDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            return false
        }

        vDown.flags = .maskCommand
        vUp.flags = .maskCommand
        vDown.post(tap: .cghidEventTap)
        vUp.post(tap: .cghidEventTap)

        return true
    }
}
