import SwiftUI

struct SettingsView: View {
    @ObservedObject var appController: AppController

    var body: some View {
        Form {
            Section("Gemini") {
                SecureField("Gemini API Key", text: apiKeyBinding)
                    .textFieldStyle(.roundedBorder)

                TextField("通常モデル", text: defaultModelBinding)
                    .textFieldStyle(.roundedBorder)

                TextField("高品質モデル", text: highQualityModelBinding)
                    .textFieldStyle(.roundedBorder)

                Text("通常は Flash-Lite、高品質モードは Flash を推奨。音声は送らず、文字起こし後テキストだけ送信します。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("整形モード") {
                Picker("デフォルトモード", selection: modeBinding) {
                    ForEach(FormattingMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
            }

            Section("ショートカット") {
                Picker("録音ショートカット", selection: shortcutBinding) {
                    ForEach(ShortcutOption.allCases) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }

                if let hint = appController.settingsStore.shortcut.conflictHint {
                    Text("注意: \(hint)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("挿入挙動") {
                Toggle("自動貼り付けを有効化", isOn: autoPasteBinding)
                Toggle("失敗時にクリップボードへコピー", isOn: copyFallbackBinding)
            }

            Section("デバッグ") {
                Toggle("デバッグログを有効化", isOn: debugLogBinding)
            }

            Section("権限") {
                HStack {
                    Text("マイク")
                    Spacer()
                    Text(appController.microphoneStatusText())
                }

                HStack {
                    Text("音声認識")
                    Spacer()
                    Text(appController.speechStatusText())
                }

                HStack {
                    Text("Accessibility")
                    Spacer()
                    Text(appController.accessibilityStatusText())
                }

                HStack {
                    Button("Accessibility権限を要求") {
                        appController.requestAccessibilityPrompt()
                    }
                    Button("Accessibility設定を開く") {
                        appController.openAccessibilitySettings()
                    }
                    Button("マイク設定を開く") {
                        appController.openMicrophoneSettings()
                    }
                }

                if let info = appController.infoMessage {
                    Text(info)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("直近履歴") {
                if appController.historyStore.entries.isEmpty {
                    Text("履歴はまだありません")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appController.historyStore.entries.prefix(5)) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.mode.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(entry.cleanedText)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 560, height: 640)
    }

    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { appController.settingsStore.apiKey },
            set: { appController.settingsStore.apiKey = $0 }
        )
    }

    private var defaultModelBinding: Binding<String> {
        Binding(
            get: { appController.settingsStore.defaultModel },
            set: { appController.settingsStore.defaultModel = $0 }
        )
    }

    private var highQualityModelBinding: Binding<String> {
        Binding(
            get: { appController.settingsStore.highQualityModel },
            set: { appController.settingsStore.highQualityModel = $0 }
        )
    }

    private var modeBinding: Binding<FormattingMode> {
        Binding(
            get: { appController.settingsStore.mode },
            set: { appController.settingsStore.mode = $0 }
        )
    }

    private var shortcutBinding: Binding<ShortcutOption> {
        Binding(
            get: { appController.settingsStore.shortcut },
            set: { appController.settingsStore.shortcut = $0 }
        )
    }

    private var autoPasteBinding: Binding<Bool> {
        Binding(
            get: { appController.settingsStore.autoPasteEnabled },
            set: { appController.settingsStore.autoPasteEnabled = $0 }
        )
    }

    private var copyFallbackBinding: Binding<Bool> {
        Binding(
            get: { appController.settingsStore.copyToClipboardOnFailure },
            set: { appController.settingsStore.copyToClipboardOnFailure = $0 }
        )
    }

    private var debugLogBinding: Binding<Bool> {
        Binding(
            get: { appController.settingsStore.debugLoggingEnabled },
            set: { appController.settingsStore.debugLoggingEnabled = $0 }
        )
    }
}
