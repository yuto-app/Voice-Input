# VoiceInput (macOS Menu Bar MVP)

macOS向けのネイティブ音声入力アプリ（MVP）です。`SwiftUI + AppKit` で実装し、**音声認識はMac上のon-device処理**、Geminiは**文字起こし後テキストの整形のみ**に使います。

## 重要な前提

- このアプリは**音声をGeminiに送信しません**
- Geminiに送るのは**文字起こし後のテキストだけ**です
- 通常モードは `gemini-2.5-flash-lite` を想定
- 高品質モードは `gemini-2.5-flash` を想定
- 一部アプリでは直接挿入が不安定なため、貼り付けフォールバックを使います
- 初回起動時にマイク権限とAccessibility権限が必要です

## 実装済み機能（MVP）

- メニューバー常駐アプリ
- グローバルショートカット（hold-to-talk）
  - `Fn` / `Option+Space` / `Control+Space` を切替可能
- 録音開始/停止
- on-deviceリアルタイム文字起こし（Apple Speech）
- 録音停止後のGemini整形
- 整形モード切替
  - プレーン整形
  - 丁寧文
  - 高品質整形（高品質モデル使用）
- 前面アプリへのテキスト挿入
  - 1) Accessibility API
  - 2) クリップボード + Cmd+V フォールバック
  - 3) 手動コピーアラート
- 権限チェック
  - マイク
  - 音声認識
  - Accessibility
- 設定画面
  - APIキー
  - 通常モデル/高品質モデル
  - 整形モード
  - ショートカット
  - 自動貼り付けON/OFF
  - 失敗時クリップボードコピーON/OFF
  - デバッグログON/OFF
- 最小履歴保存（直近50件）
- エラー/状態表示
  - `Idle`, `Listening`, `Transcribing`, `Processing`, `Inserting`, `Error`

## ディレクトリ構成

```text
Sources/VoiceInput
├── App
│   ├── AppController.swift
│   └── VoiceInputApp.swift
├── Features
│   ├── MenuBar
│   ├── Recorder
│   └── Settings
├── Services
│   ├── Audio
│   ├── Gemini
│   ├── Hotkey
│   ├── Insertion
│   ├── Permissions
│   └── Speech
├── Shared
│   ├── Models
│   ├── Stores
│   └── Utilities
└── Resources
    └── Info.plist
```

## セットアップ

1. Gemini APIキーを用意
2. このディレクトリでビルド

```bash
swift build
```

3. 実行

```bash
swift run VoiceInput
```

4. メニューバーから `設定` を開き、APIキーとモデルを確認

## 権限設定

初回起動時または設定画面から以下を許可してください。

- マイク
- 音声認識
- Accessibility

Accessibility未許可でも動作はしますが、直接挿入成功率が下がり、フォールバック利用が増えます。

## 設定例

`.env.example` を参照してください。環境変数 `GEMINI_API_KEY` を使うか、設定画面に入力します。

## 実行時フロー

1. ショートカット押下で録音開始（押している間だけ録音）
2. on-deviceでリアルタイム文字起こし
3. キーを離して録音停止
4. 文字起こしテキストをGeminiへ送信して整形
5. 整形テキストを前面アプリへ挿入
6. 失敗時は貼り付けフォールバック、さらに失敗時は手動コピー

## 既知の制限

- `Fn` 単体検出はキーボード/IME環境によって挙動差があります
- Google Docsや一部独自エディタでは直接挿入が失敗しやすいです（貼り付けフォールバック前提）
- on-device認識の品質はOS/言語設定の影響を受けます
- CLI実行のため、配布用 `.app` バンドル化（署名/Notarization）は未対応

## テスト観点（推奨）

- 日本語のみ / 英語のみ / 混在入力
- フィラー多め発話
- 短文連続 / 長文
- 録音直後停止
- APIキー未設定
- ネットワークエラー
- Accessibilityなし / マイクなし
- 各種入力先（メモ, TextEdit, Slack, Notion, ブラウザ）

## 拡張ポイント

### 整形ルールを追加する

- `Sources/VoiceInput/Services/Gemini/GeminiFormattingService.swift`
  - `systemInstruction(for:)` にモード別ルールを追加

### モデルを追加する

- `Sources/VoiceInput/Shared/Models/FormattingMode.swift`
  - 新モード追加
- `Sources/VoiceInput/Services/Gemini/GeminiFormattingService.swift`
  - モードとモデルの紐付け追加
- `Sources/VoiceInput/Features/Settings/SettingsView.swift`
  - 設定UIの選択肢追加

### アプリ別ルールを追加する

- `Sources/VoiceInput/App/AppController.swift`
  - 挿入前に前面アプリBundle IDを見てモード/プロンプト切替する分岐を追加
- 将来用に `Services/Gemini` に `AppProfilePromptResolver` などを追加する想定

## 今後の拡張候補

- アプリ別プロンプト
- メール文モード
- Slack向け短文化モード
- 箇条書き整形モード
- 句読点弱めモード
- 録音履歴UI
- 直近結果の再送
- 手動編集してから挿入する確認UI
