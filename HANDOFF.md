# HANDOFF

このファイルは、複数のAI/開発者（Codex、Claude Code、Antigravity など）が同じリポジトリを引き継いで作業するための共通ログです。

## 記入ルール

1. 新しい記録は必ずこのルール直下の「作業ログ」先頭に追記する（最新が一番上）。
2. 記入日時は `YYYY-MM-DD HH:mm:ss JST` で明記する。
3. 作業アプリ名を明記する（例: `Codex` / `Claude Code` / `Antigravity`）。
4. 1エントリにつき、以下の必須項目をすべて埋める。
5. 既存エントリの内容を上書き・削除しない。訂正が必要な場合は新しいエントリで追記する。
6. 未完了事項・制限事項・次担当への依頼を必ず残す。
7. 変更ファイルは主要ファイルを列挙する（必要なら「他 N 件」と省略可）。
8. 動作確認コマンドと結果を明記する（未実施なら理由を書く）。

### 必須項目

- 記入日時
- 作業アプリ
- 担当（任意名）
- 目的/チケット
- 実施内容
- 変更ファイル
- 動作確認
- 未完了/制限事項
- 次担当への引き継ぎ

### 記入テンプレート

```md
### [YYYY-MM-DD HH:mm:ss JST] [作業アプリ]
- 担当: 
- 目的/チケット: 
- 実施内容:
- 変更ファイル:
- 動作確認:
- 未完了/制限事項:
- 次担当への引き継ぎ:
```

## 作業ログ（新しい順）

### [2026-03-01 13:33:21 JST] [Codex]
- 担当: Codex (GPT-5)
- 目的/チケット: macOS音声入力アプリMVPの新規実装（on-device音声認識 + Gemini整形）
- 実施内容:
  - Swift Packageベースで macOS メニューバーアプリを新規実装。
  - サービス分離アーキテクチャを作成（Audio/Speech/Gemini/Insertion/Permissions/Hotkey/Settings/History）。
  - hold-to-talk（Fn / Option+Space / Control+Space）を実装。
  - Apple Speech の on-device 認識を使ったリアルタイム文字起こしを実装。
  - 録音停止後に Gemini API へ「文字起こし後テキストのみ」を送る整形処理を実装。
  - 整形モード（プレーン/丁寧文/高品質）を実装。
  - 前面アプリ挿入の3段フォールバック（Accessibility -> Cmd+V -> 手動コピー）を実装。
  - 権限チェックUI（マイク/音声認識/Accessibility）と設定画面を実装。
  - README と `.env.example` を作成。
- 変更ファイル:
  - `Package.swift`
  - `Sources/VoiceInput/App/AppController.swift`
  - `Sources/VoiceInput/App/VoiceInputApp.swift`
  - `Sources/VoiceInput/Features/MenuBar/MenuBarView.swift`
  - `Sources/VoiceInput/Features/Recorder/RecorderStatusView.swift`
  - `Sources/VoiceInput/Features/Settings/SettingsView.swift`
  - `Sources/VoiceInput/Services/Audio/AudioCaptureService.swift`
  - `Sources/VoiceInput/Services/Speech/SpeechRecognitionService.swift`
  - `Sources/VoiceInput/Services/Gemini/GeminiFormattingService.swift`
  - `Sources/VoiceInput/Services/Insertion/TextInsertionService.swift`
  - `Sources/VoiceInput/Services/Permissions/PermissionsService.swift`
  - `Sources/VoiceInput/Services/Hotkey/HotkeyService.swift`
  - `Sources/VoiceInput/Shared/Models/AppState.swift`
  - `Sources/VoiceInput/Shared/Models/FormattingMode.swift`
  - `Sources/VoiceInput/Shared/Models/ShortcutOption.swift`
  - `Sources/VoiceInput/Shared/Stores/SettingsStore.swift`
  - `Sources/VoiceInput/Shared/Stores/HistoryStore.swift`
  - `Sources/VoiceInput/Shared/Utilities/AppLogger.swift`
  - `Sources/VoiceInput/Resources/Info.plist`
  - `README.md`
  - `.env.example`
  - `HANDOFF.md`
- 動作確認:
  - コマンド: `swift build`
  - 結果: 成功（Build complete!）
  - 補足: この作業ディレクトリは Git 管理外（`.git` なし）
- 未完了/制限事項:
  - アプリ別整形ルールの自動切替は未実装。
  - 任意キー学習型のホットキー設定は未実装（プリセット選択のみ）。
  - `.app` バンドル化/署名/Notarization は未対応。
  - `Fn` 単体検出は環境依存で不安定なケースあり。
- 次担当への引き継ぎ:
  - 1) アプリ別ルール: 前面アプリBundle ID取得 + Geminiプロンプト切替レイヤー追加。
  - 2) 設定拡張: モード追加UI（メール/Slack/箇条書き等）と永続化。
  - 3) 配布準備: Xcodeプロジェクト化または `.app` 生成フロー整備。
  - 4) 実機確認: Slack/Notion/Browser/Google Docs で挿入フォールバック挙動を検証。
