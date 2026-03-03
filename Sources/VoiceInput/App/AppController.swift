import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppController: ObservableObject {
    @Published var state: AppState = .idle
    @Published var liveTranscript: String = ""
    @Published var lastFormattedText: String = ""
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    let settingsStore: SettingsStore
    let historyStore: HistoryStore

    private let audioCaptureService: AudioCaptureService
    private let speechRecognitionService: SpeechRecognitionService
    private let geminiFormattingService: GeminiFormattingService
    private let textInsertionService: TextInsertionService
    private let permissionsService: PermissionsService
    private let hotkeyService: HotkeyService

    private var cancellables = Set<AnyCancellable>()
    private var isRecording = false
    private var settingsWindow: NSWindow?
    private var hudPanel: NSPanel?

    init(
        settingsStore: SettingsStore = SettingsStore(),
        historyStore: HistoryStore = HistoryStore(),
        audioCaptureService: AudioCaptureService = AudioCaptureService(),
        speechRecognitionService: SpeechRecognitionService = SpeechRecognitionService(),
        geminiFormattingService: GeminiFormattingService = GeminiFormattingService(),
        textInsertionService: TextInsertionService = TextInsertionService(),
        permissionsService: PermissionsService = PermissionsService()
    ) {
        self.settingsStore = settingsStore
        self.historyStore = historyStore
        self.audioCaptureService = audioCaptureService
        self.speechRecognitionService = speechRecognitionService
        self.geminiFormattingService = geminiFormattingService
        self.textInsertionService = textInsertionService
        self.permissionsService = permissionsService
        self.hotkeyService = HotkeyService(shortcut: settingsStore.shortcut)

        bindSettings()
        configureHotkeyCallbacks()
    }

    func start() {
        hotkeyService.start()
        refreshPermissionHints()
    }

    func stop() {
        hotkeyService.stop()
        audioCaptureService.stopCapture()
        speechRecognitionService.stopImmediately()
    }

    func startRecordingFromMenu() {
        Task {
            await startRecordingIfNeeded(triggeredByHotkey: false)
        }
    }

    func stopRecordingFromMenu() {
        Task {
            await stopRecordingAndProcess()
        }
    }

    func requestAccessibilityPrompt() {
        _ = permissionsService.isAccessibilityTrusted(prompt: true)
        refreshPermissionHints()
    }

    func openAccessibilitySettings() {
        permissionsService.openSystemSettingsForAccessibility()
    }

    func openMicrophoneSettings() {
        permissionsService.openSystemSettingsForMicrophone()
    }

    func openSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "VoiceInput 設定"
            window.contentView = NSHostingView(rootView: SettingsView(appController: self))
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func refreshPermissionHints() {
        let missing = permissionsService.missingPermissionMessages()
        if missing.isEmpty {
            infoMessage = nil
        } else {
            infoMessage = missing.joined(separator: " / ")
        }
    }

    func microphoneStatusText() -> String {
        statusText(for: permissionsService.microphoneStatus())
    }

    func speechStatusText() -> String {
        statusText(for: permissionsService.speechStatus())
    }

    func accessibilityStatusText() -> String {
        permissionsService.isAccessibilityTrusted() ? "許可済み" : "未許可"
    }

    // MARK: - Recording HUD

    private func showRecordingHUD() {
        if hudPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 320, height: 60),
                styleMask: [.nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true

            let hudView = NSHostingView(rootView: RecordingHUDView(appController: self))
            hudView.frame = NSRect(x: 0, y: 0, width: 320, height: 60)
            panel.contentView = hudView

            if let screen = NSScreen.main {
                let x = screen.frame.origin.x + (screen.frame.width - 320) / 2
                let y = screen.frame.origin.y + screen.frame.height - 120
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }

            hudPanel = panel
        }
        hudPanel?.orderFrontRegardless()
    }

    private func hideRecordingHUD() {
        hudPanel?.orderOut(nil)
    }

    private func bindSettings() {
        settingsStore.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settingsStore.$shortcut
            .removeDuplicates()
            .sink { [weak self] shortcut in
                self?.hotkeyService.updateShortcut(shortcut)
            }
            .store(in: &cancellables)
    }

    private func configureHotkeyCallbacks() {
        hotkeyService.onPress = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.startRecordingIfNeeded(triggeredByHotkey: true)
            }
        }

        hotkeyService.onRelease = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.stopRecordingAndProcess()
            }
        }

        hotkeyService.onFailure = { [weak self] message in
            Task { @MainActor in
                self?.setError(message)
            }
        }
    }

    private func startRecordingIfNeeded(triggeredByHotkey: Bool) async {
        guard !isRecording else { return }

        if state == .processing || state == .inserting {
            return
        }

        clearMessages()

        let hasMicPermission = await permissionsService.requestMicrophonePermission()
        let hasSpeechPermission = await permissionsService.requestSpeechPermission()

        guard hasMicPermission else {
            setError("マイク権限がありません。設定から許可してください。")
            return
        }

        guard hasSpeechPermission else {
            setError("音声認識権限がありません。設定から許可してください。")
            return
        }

        if !permissionsService.isAccessibilityTrusted() {
            infoMessage = "Accessibility権限がないため、直接挿入に失敗しやすくなります。"
        }

        do {
            liveTranscript = ""
            lastFormattedText = ""
            state = .listening

            try speechRecognitionService.startRecognition { [weak self] partialText in
                Task { @MainActor in
                    guard let self else { return }
                    self.liveTranscript = partialText
                    if !partialText.isEmpty {
                        self.state = .transcribing
                    }
                }
            }

            try audioCaptureService.startCapture { [weak self] buffer, _ in
                self?.speechRecognitionService.appendAudioBuffer(buffer)
            }

            isRecording = true
            showRecordingHUD()
            AppLogger.app.debug("Recording started via \(triggeredByHotkey ? "hotkey" : "menu", privacy: .public)")
        } catch {
            isRecording = false
            speechRecognitionService.stopImmediately()
            audioCaptureService.stopCapture()
            setError("録音開始に失敗: \(error.localizedDescription)")
        }
    }

    private func stopRecordingAndProcess() async {
        guard isRecording else { return }

        // Gemini処理前にフォーカスアプリを記憶する
        let targetApp = NSWorkspace.shared.frontmostApplication

        isRecording = false
        hideRecordingHUD()
        audioCaptureService.stopCapture()
        try? await Task.sleep(nanoseconds: 350_000_000)

        let rawTranscript = speechRecognitionService.stopRecognition().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !rawTranscript.isEmpty else {
            setError("音声が認識されませんでした。")
            return
        }

        state = .processing
        let settings = settingsStore.snapshot()
        var cleanedText = rawTranscript

        if settings.apiKey.isEmpty {
            infoMessage = "APIキー未設定のため、整形せずに挿入します。"
        } else {
            do {
                cleanedText = try await geminiFormattingService.formatText(rawText: rawTranscript, settings: settings)
            } catch {
                infoMessage = "整形に失敗したため、生テキストを挿入します。"
                AppLogger.gemini.error("Formatting fallback used: \(error.localizedDescription, privacy: .public)")
            }
        }

        // 挿入前に元のアプリへフォーカスを戻す（Electronアプリ対応で400msに延長）
        state = .inserting
        let bundleID = targetApp?.bundleIdentifier ?? "unknown"
        AppLogger.insertion.debug("Activating target app: \(bundleID, privacy: .public)")
        targetApp?.activate()
        try? await Task.sleep(nanoseconds: 400_000_000)
        let insertionResult = textInsertionService.insert(text: cleanedText, settings: settings)
        AppLogger.insertion.debug("Insertion result: \(String(describing: insertionResult), privacy: .public) for \(bundleID, privacy: .public)")
        lastFormattedText = cleanedText
        historyStore.append(raw: rawTranscript, cleaned: cleanedText, mode: settings.mode)

        switch insertionResult {
        case .insertedDirectly:
            infoMessage = "直接挿入しました。"
        case .insertedViaPaste:
            infoMessage = "貼り付けフォールバックで挿入しました。"
        case .copiedToClipboard:
            infoMessage = "自動挿入に失敗。クリップボードへコピーしました。"
            showManualCopyAlert(text: cleanedText)
        case .manualRequired:
            showManualCopyAlert(text: cleanedText)
        }

        state = .idle
    }

    private func showManualCopyAlert(text: String) {
        let alert = NSAlert()
        alert.messageText = "自動挿入に失敗しました"
        alert.informativeText = "結果を手動で貼り付けてください。"
        alert.addButton(withTitle: "コピー")
        alert.addButton(withTitle: "閉じる")

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            textInsertionService.copyToClipboard(text)
        }
    }

    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }

    private func setError(_ message: String) {
        errorMessage = message
        state = .error
    }

    private func statusText(for status: PermissionsService.PermissionStatus) -> String {
        switch status {
        case .authorized:
            return "許可済み"
        case .denied:
            return "拒否"
        case .restricted:
            return "制限あり"
        case .notDetermined:
            return "未確認"
        }
    }
}
