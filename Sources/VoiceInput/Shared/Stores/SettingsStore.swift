import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    struct Snapshot {
        let apiKey: String
        let defaultModel: String
        let highQualityModel: String
        let mode: FormattingMode
        let shortcut: ShortcutOption
        let autoPasteEnabled: Bool
        let copyToClipboardOnFailure: Bool
        let debugLoggingEnabled: Bool
    }

    private enum Keys {
        static let apiKey = "settings.apiKey"
        static let defaultModel = "settings.defaultModel"
        static let highQualityModel = "settings.highQualityModel"
        static let mode = "settings.mode"
        static let shortcut = "settings.shortcut"
        static let autoPasteEnabled = "settings.autoPasteEnabled"
        static let copyToClipboardOnFailure = "settings.copyToClipboardOnFailure"
        static let debugLoggingEnabled = "settings.debugLoggingEnabled"
    }

    private let defaults: UserDefaults
    @Published var apiKey: String { didSet { save(apiKey, key: Keys.apiKey) } }
    @Published var defaultModel: String { didSet { save(defaultModel, key: Keys.defaultModel) } }
    @Published var highQualityModel: String { didSet { save(highQualityModel, key: Keys.highQualityModel) } }
    @Published var mode: FormattingMode { didSet { save(mode.rawValue, key: Keys.mode) } }
    @Published var shortcut: ShortcutOption { didSet { save(shortcut.rawValue, key: Keys.shortcut) } }
    @Published var autoPasteEnabled: Bool { didSet { save(autoPasteEnabled, key: Keys.autoPasteEnabled) } }
    @Published var copyToClipboardOnFailure: Bool { didSet { save(copyToClipboardOnFailure, key: Keys.copyToClipboardOnFailure) } }
    @Published var debugLoggingEnabled: Bool { didSet { save(debugLoggingEnabled, key: Keys.debugLoggingEnabled) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let envAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
        let storedAPIKey = defaults.string(forKey: Keys.apiKey) ?? ""
        self.apiKey = storedAPIKey.isEmpty ? envAPIKey : storedAPIKey

        self.defaultModel = defaults.string(forKey: Keys.defaultModel) ?? "gemini-2.5-flash-lite"
        self.highQualityModel = defaults.string(forKey: Keys.highQualityModel) ?? "gemini-2.5-flash"

        if let rawMode = defaults.string(forKey: Keys.mode),
           let mode = FormattingMode(rawValue: rawMode) {
            self.mode = mode
        } else {
            self.mode = .plain
        }

        if let rawShortcut = defaults.string(forKey: Keys.shortcut),
           let shortcut = ShortcutOption(rawValue: rawShortcut) {
            self.shortcut = shortcut
        } else {
            self.shortcut = .fnHold
        }

        if defaults.object(forKey: Keys.autoPasteEnabled) == nil {
            self.autoPasteEnabled = true
        } else {
            self.autoPasteEnabled = defaults.bool(forKey: Keys.autoPasteEnabled)
        }

        if defaults.object(forKey: Keys.copyToClipboardOnFailure) == nil {
            self.copyToClipboardOnFailure = true
        } else {
            self.copyToClipboardOnFailure = defaults.bool(forKey: Keys.copyToClipboardOnFailure)
        }

        self.debugLoggingEnabled = defaults.bool(forKey: Keys.debugLoggingEnabled)
    }

    func snapshot() -> Snapshot {
        Snapshot(
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            defaultModel: defaultModel.trimmingCharacters(in: .whitespacesAndNewlines),
            highQualityModel: highQualityModel.trimmingCharacters(in: .whitespacesAndNewlines),
            mode: mode,
            shortcut: shortcut,
            autoPasteEnabled: autoPasteEnabled,
            copyToClipboardOnFailure: copyToClipboardOnFailure,
            debugLoggingEnabled: debugLoggingEnabled
        )
    }

    private func save<T>(_ value: T, key: String) {
        defaults.set(value, forKey: key)
    }
}
