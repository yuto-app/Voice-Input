import AppKit
import ApplicationServices
import Foundation

final class HotkeyService {
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?
    var onFailure: ((String) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var shortcut: ShortcutOption
    private var isPressed = false

    init(shortcut: ShortcutOption) {
        self.shortcut = shortcut
    }

    func start() {
        guard eventTap == nil else { return }

        let mask = (
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }

            let service = Unmanaged<HotkeyService>.fromOpaque(userInfo).takeUnretainedValue()
            return service.handle(event: event, type: type)
        }

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            onFailure?("グローバルショートカットを監視できません。Accessibility権限を確認してください。")
            return
        }

        self.eventTap = eventTap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        AppLogger.hotkey.debug("Hotkey monitoring started")
    }

    func stop() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: false)

        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }

        self.runLoopSource = nil
        self.eventTap = nil
        self.isPressed = false
        AppLogger.hotkey.debug("Hotkey monitoring stopped")
    }

    func updateShortcut(_ shortcut: ShortcutOption) {
        self.shortcut = shortcut
        self.isPressed = false
        AppLogger.hotkey.debug("Hotkey updated: \(shortcut.rawValue, privacy: .public)")
    }

    private func handle(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        case .keyDown, .keyUp, .flagsChanged:
            processKeyEvent(event: event, type: type)
            return Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func processKeyEvent(event: CGEvent, type: CGEventType) {
        switch shortcut {
        case .fnHold:
            processFnHold(event: event, type: type)
        case .optionSpaceHold:
            processModifiedSpace(event: event, type: type, modifier: .maskAlternate)
        case .controlSpaceHold:
            processModifiedSpace(event: event, type: type, modifier: .maskControl)
        }
    }

    private func processFnHold(event: CGEvent, type: CGEventType) {
        guard type == .flagsChanged else { return }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == 63 else { return }

        let pressed = event.flags.contains(.maskSecondaryFn)
        if pressed && !isPressed {
            isPressed = true
            onPress?()
        } else if !pressed && isPressed {
            isPressed = false
            onRelease?()
        }
    }

    private func processModifiedSpace(event: CGEvent, type: CGEventType, modifier: CGEventFlags) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == 49 else { return } // Space key

        switch type {
        case .keyDown:
            let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1
            guard !isRepeat, event.flags.contains(modifier) else { return }
            if !isPressed {
                isPressed = true
                onPress?()
            }
        case .keyUp:
            if isPressed {
                isPressed = false
                onRelease?()
            }
        default:
            break
        }
    }
}
