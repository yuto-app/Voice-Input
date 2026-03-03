import Foundation

struct GeminiFormattingService {
    enum GeminiError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Gemini API key is missing."
            case .invalidResponse:
                return "Failed to parse Gemini response."
            case let .apiError(message):
                return "Gemini API error: \(message)"
            }
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func formatText(rawText: String, settings: SettingsStore.Snapshot) async throws -> String {
        let apiKey = settings.apiKey
        guard !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        let model = settings.mode.modelTier == .highQuality ? settings.highQualityModel : settings.defaultModel
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: endpoint) else {
            throw GeminiError.invalidResponse
        }

        let requestBody = GeminiRequest(
            systemInstruction: .init(parts: [.init(text: systemInstruction(for: settings.mode))]),
            contents: [
                .init(role: "user", parts: [.init(text: "Raw transcript:\n\(rawText)")])
            ],
            generationConfig: .init(temperature: 0.2, topP: 0.8, maxOutputTokens: 2048)
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError(message)
        }

        let parsed = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = parsed.candidates.first?.content.parts.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw GeminiError.invalidResponse
        }

        AppLogger.gemini.debug("model=\(model, privacy: .public) input=\(String(rawText.prefix(100)), privacy: .public) output=\(String(text.prefix(100)), privacy: .public)")
        return text
    }

    private func systemInstruction(for mode: FormattingMode) -> String {
        let common = """
        あなたはmacOS音声認識テキストの整形アシスタントです。
        入力はSiri音声入力エンジンが生成した日本語テキストです。音声入力特有の問題を積極的に修正してください。

        ## 必ず処理すること
        - フィラーの削除：「えー」「えっと」「あのー」「あの」「そのー」「まあ」「うーん」などの間投詞を削除する
        - 言い直しの整理：「資料を〜、あ、ファイルを送って」のような言い直しは後半だけ残す
        - 句読点の補完：自然な位置に「。」「、」を追加する（元々ない場合）
        - 話し言葉を書き言葉へ変換する：
          ・「〜っていう」→「〜という」
          ・「〜なんだけど」「〜なんですが」→「〜ですが」
          ・「〜じゃないですか」→「〜ではないでしょうか」
          ・「〜しといて」→「〜しておいて」
          ・「〜てもらえます」→「〜ていただけますか」

        ## 変更してはいけないこと
        - 内容・事実・数字・固有名詞を変えない、追加しない
        - 音声認識誤りと断定できない固有名詞や専門用語は修正しない
        - 意味の大幅な言い換えはしない

        ## 出力形式
        整形後のテキストのみを出力。前置き・説明・引用符は不要。
        """

        switch mode {
        case .plain:
            return common + "\n## 文体\n普通体（だ・である調）で整える。"
        case .polite:
            return common + "\n## 文体\n丁寧語（です・ます調）に統一する。"
        case .highQuality:
            return common + "\n## 文体\n読みやすく洗練された書き言葉に整える。文脈に合わせて最適な表現を選ぶ。"
        }
    }
}

private struct GeminiRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable {
            let text: String
        }

        let role: String?
        let parts: [Part]

        init(role: String? = nil, parts: [Part]) {
            self.role = role
            self.parts = parts
        }
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
        let topP: Double
        let maxOutputTokens: Int
    }

    let systemInstruction: Content
    let contents: [Content]
    let generationConfig: GenerationConfig
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String?
            }

            let parts: [Part]
        }

        let content: Content
    }

    let candidates: [Candidate]
}
