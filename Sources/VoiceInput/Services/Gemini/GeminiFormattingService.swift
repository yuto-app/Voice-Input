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

        return text
    }

    private func systemInstruction(for mode: FormattingMode) -> String {
        let common = """
        あなたは音声入力テキストの整形アシスタントです。
        要約ではなく整形を行ってください。意味を変えないでください。
        以下の整形を行ってください：
        - 日本語には句読点（。、）を自然に補う
        - 英語にはピリオドやカンマを自然に補う
        - 話し言葉を自然な書き言葉に近づける
        - 不明瞭な箇所は勝手に補完しない
        - 事実や情報を追加しない
        - 不確かな固有名詞は無理に修正しない
        - 短文はそのまま短文で出力する
        整形後のテキストのみを出力してください。説明や前置きは不要です。
        """

        switch mode {
        case .plain:
            return common + "\n文体：自然な普通体。"
        case .polite:
            return common + "\n文体：日本語の場合は丁寧語（ですます調）に整える。"
        case .highQuality:
            return common + "\n文体：高品質だが原文に忠実に。読みやすさを重視して整形する。"
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
