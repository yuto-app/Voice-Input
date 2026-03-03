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

### [2026-03-03 Claude Code]
- 担当: Claude Code (claude-sonnet-4-6)
- 目的/チケット: MEMO.md のフィードバック対応（整形品質・視覚的フィードバック・挿入改善）
- 実施内容:
  - **Gemini整形プロンプトの全面改訂**: 従来のプロンプトが過度に保守的で整形効果がほぼゼロだった問題を修正。フィラー削除（えー・えっと・あのー等）の明示、言い直し整理、話し言葉→書き言葉変換の具体例追加（「〜っていう」→「〜という」等）。
  - **Geminiデバッグログ追加**: `AppLogger.gemini.debug` で入力テキスト・出力テキスト・モデル名をログに記録するよう追加。整形前後の差分がConsole.appで確認可能に。
  - **録音中フローティングHUD追加**: Fn押下中に画面に何も表示されない問題を解決。`RecordingHUDView.swift` を新規作成し、`AppController` に `NSPanel` ベースの HUD 管理を追加。録音開始時に画面上部中央に「● 録音中」「● 文字起こし中」のオーバーレイが表示され、ライブ文字起こしも60文字まで表示される。
  - **挿入待機時間を延長**: Gemini処理後の `targetApp.activate()` からペーストまでの待機を100ms→400msに延長。Electron製アプリ（Antigravity等）やブラウザへの挿入成功率が向上する見込み。
  - **挿入デバッグログ追加**: 対象アプリのBundle ID・挿入結果をログに記録。
- 変更ファイル:
  - `Sources/VoiceInput/Services/Gemini/GeminiFormattingService.swift`（プロンプト改訂・ログ追加）
  - `Sources/VoiceInput/App/AppController.swift`（HUD管理・待機延長・ログ追加）
  - `Sources/VoiceInput/Features/Recorder/RecordingHUDView.swift`（新規作成）
- 動作確認:
  - コマンド: `swift build -c release && cp .build/release/VoiceInput VoiceInput.app/Contents/MacOS/VoiceInput && codesign --force --deep --sign - VoiceInput.app`
  - 結果: Build complete!、署名完了
  - 実機確認: **未実施**（ユーザーによるテストを待機）
- 未完了/制限事項:
  - **HUD高さ固定（60px）**: 文字起こしが長くなっても高さは変わらない。必要なら NSPanel + NSHostingView の autosizing を改善。
  - **HUDがメニューバークリック時も表示される**: メニュー経由で録音開始した場合も HUD が出る（想定動作）。
  - **Antigravity への直接挿入**: Electron アプリへの Accessibility API 挿入は引き続き不可。ペーストフォールバック（400ms delay）で対応。
  - **モード選択**: コードレビューで問題なしと判断したが、実機テストは未実施。
- 次担当への引き継ぎ:
  - **最優先: 実機テスト**
    1. 録音中にHUDが画面上部に表示されるか
    2. Gemini整形後に文章が変わっているか（フィラーが消えているか）
    3. Antigravity チャットに貼り付けが成功するか
    4. モード「丁寧文」選択後に保持されるか
  - **再ビルド手順**:
    ```
    pkill -f VoiceInput
    swift build -c release
    cp .build/release/VoiceInput VoiceInput.app/Contents/MacOS/VoiceInput
    codesign --force --deep --sign - VoiceInput.app
    open VoiceInput.app
    # システム設定 → アクセシビリティ で VoiceInput のチェックを外して再チェック
    ```
  - **ログ確認**: Console.app で "VoiceInput" を検索 → Gemini カテゴリで input/output を確認可能。



### [2026-03-01 15:17:47 JST] [Claude Code]
- 担当: Claude Code (claude-sonnet-4-6)
- 目的/チケット: 実機動作確認・バグ修正・Gemini整形の品質改善
- 実施内容:
  - **PermissionsService クラッシュ修正**: `requestSpeechPermission()` が `@MainActor` クラスのコールバックをバックグラウンドスレッドから呼んでクラッシュしていた。`Task.detached` で MainActor 外で continuation を実行するよう変更。
  - **SpeechRecognitionService 音声欠落修正**: Apple Speech の on-device 認識がセグメントをリセットする仕様により、長い発話の前半が消えていた。`accumulatedTranscript` で確定済みセグメントを蓄積するよう変更。
  - **設定ウィンドウ修正**: `NSApp.sendAction(Selector(("showSettingsWindow:")))` がメニューバーアクセサリアプリで機能しない問題。`AppController` に `NSWindow` + `NSHostingView(rootView: SettingsView(...))` で直接ウィンドウを生成する `openSettingsWindow()` を実装。
  - **テキスト挿入先フォーカス修正**: Gemini 処理中（2〜3秒）にフォーカスが移動してしまい元アプリにテキストが挿入されない問題。`stopRecordingAndProcess()` で録音停止直後に `NSWorkspace.shared.frontmostApplication` を保存し、挿入前に `activate()` するよう変更。
  - **.app バンドル手動作成**: Accessibility 権限の登録に `.app` バンドルが必要なため、`VoiceInput.app/Contents/MacOS/` 構造を手動作成し ad-hoc 署名で運用。
  - **モード選択スナップバック修正**: 整形モード Picker で「丁寧文」「高品質」を選択しても「プレーン」に戻る問題。`AppController.bindSettings()` に `settingsStore.objectWillChange` の転送（`self?.objectWillChange.send()`）を追加し、観察側の SwiftUI ビューが再レンダリングされるよう修正。
  - **Gemini システムプロンプト更新**: macOS の on-device 音声認識がフィラー（えー・あのー等）を自動除去していることが判明したため、フィラー削除指示をプロンプトから削除。句読点補完・書き言葉変換に集中した内容に変更。ただしMac側でフィラー削除が効かない場合に備え、将来復活の余地あり（下記「未完了」参照）。
- 変更ファイル:
  - `Sources/VoiceInput/Services/Permissions/PermissionsService.swift`
  - `Sources/VoiceInput/Services/Speech/SpeechRecognitionService.swift`
  - `Sources/VoiceInput/App/AppController.swift`
  - `Sources/VoiceInput/Services/Gemini/GeminiFormattingService.swift`
  - `VoiceInput.app/` （バンドル構造・バイナリ・署名）
- 動作確認:
  - コマンド: `swift build -c release && cp .build/release/VoiceInput VoiceInput.app/Contents/MacOS/VoiceInput && codesign --force --deep --sign - VoiceInput.app`
  - 結果: Build complete!、署名完了
  - 実機確認済み（ユーザー報告）:
    - Fn キーによる hold-to-talk → 録音・文字起こし・挿入（メモアプリ）OK
    - Gemini API 呼び出し（整形）が動作していることを確認（「整形に失敗したため」メッセージなし）
    - 長い発話でも前半が欠落しないことを確認
  - モード選択修正後の再テスト: **未実施**（ユーザーが今日テスト不可のため）
- 未完了/制限事項:
  - **モード選択修正の動作確認が未実施**: 次回起動後に「丁寧文」「高品質整形」が選択・保持されるか確認が必要。
  - **Gemini フィラー削除プロンプト**: Mac 側の音声認識でフィラーが削除されない環境・ケースが確認された場合は、プロンプトにフィラー削除指示を復活させること。
  - **VSCode / Electron アプリへの直接挿入不可**: クリップボードフォールバックは機能するが、直接挿入は Accessibility API の制約で動作しない（非クリティカル）。
  - **再ビルドのたびに Accessibility 再登録が必要**: ad-hoc 署名のためバイナリが変わると再登録が必要（システム設定 → プライバシー → アクセシビリティ）。
  - **アイコンが 2 つ表示される**: MenuBarExtra + NSApp がそれぞれアイコンを出す。起動方法の改善余地あり。
- 次担当への引き継ぎ:
  - **最優先: モード選択の動作確認**: 起動後に設定ウィンドウで「丁寧文」を選択し、保持されるか確認。問題があれば `AppController.bindSettings()` の `objectWillChange` 転送ロジックを再確認。
  - **Gemini 整形品質の確認**: 録音後に句読点が追加されているか、書き言葉変換が自然かを確認。Mac 音声認識でフィラーが残る場合は `GeminiFormattingService.swift` の `common` プロンプトにフィラー削除行を追加。
  - **再ビルド手順**（参考）:
    ```
    pkill -f VoiceInput
    swift build -c release
    cp .build/release/VoiceInput VoiceInput.app/Contents/MacOS/VoiceInput
    codesign --force --deep --sign - VoiceInput.app
    open VoiceInput.app
    # → システム設定 → アクセシビリティ で VoiceInput のチェックを外して再度チェック
    ```
  - 将来タスク（優先度低）: VSCode 等 Electron アプリへの挿入改善、.app バンドル自動化、アイコン重複解消。

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
