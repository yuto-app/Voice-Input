import AVFoundation
import AppKit
import ApplicationServices
import Foundation
import Speech

@MainActor
final class PermissionsService {
    enum PermissionStatus: String {
        case authorized
        case denied
        case restricted
        case notDetermined
    }

    func microphoneStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func speechStatus() -> PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func isAccessibilityTrusted(prompt: Bool = false) -> Bool {
        if prompt {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    func requestMicrophonePermission() async -> Bool {
        if microphoneStatus() == .authorized {
            return true
        }

        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func requestSpeechPermission() async -> Bool {
        if speechStatus() == .authorized {
            return true
        }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func openSystemSettingsForAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func openSystemSettingsForMicrophone() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    func missingPermissionMessages() -> [String] {
        var messages: [String] = []

        if microphoneStatus() != .authorized {
            messages.append("マイク権限が未許可です")
        }

        if speechStatus() != .authorized {
            messages.append("音声認識権限が未許可です")
        }

        if !isAccessibilityTrusted() {
            messages.append("Accessibility権限が未許可です")
        }

        return messages
    }
}
