import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appController: AppController

    private var modeBinding: Binding<FormattingMode> {
        Binding(
            get: { appController.settingsStore.mode },
            set: { appController.settingsStore.mode = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Input")
                .font(.headline)

            RecorderStatusView(
                state: appController.state,
                transcript: appController.liveTranscript,
                formattedText: appController.lastFormattedText
            )

            Picker("整形モード", selection: modeBinding) {
                ForEach(FormattingMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }

            HStack {
                Button(action: toggleRecording) {
                    Text(isRecording ? "停止して整形" : "録音開始")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.return)
            }

            Text("ショートカット: \(appController.settingsStore.shortcut.title)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let infoMessage = appController.infoMessage {
                Text(infoMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = appController.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack {
                Button("設定") {
                    appController.openSettingsWindow()
                }

                Spacer()

                Button("終了") {
                    appController.stop()
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    private var isRecording: Bool {
        appController.state == .listening || appController.state == .transcribing
    }

    private func toggleRecording() {
        if isRecording {
            appController.stopRecordingFromMenu()
        } else {
            appController.startRecordingFromMenu()
        }
    }
}
