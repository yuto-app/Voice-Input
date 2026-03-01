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
        You are a speech input text formatter.
        Do formatting, not summarization.
        Never change the user's meaning.
        Remove fillers (like um/uh/えー/あのー), clean obvious self-corrections, add natural punctuation, and fix minor typos only.
        Do not add facts or inferred details.
        Do not aggressively rewrite names you are unsure about.
        Keep short utterances short.
        Output only the cleaned text.
        """

        switch mode {
        case .plain:
            return common + "\nTone: neutral natural writing style."
        case .polite:
            return common + "\nTone: polite Japanese (丁寧語) when the sentence is Japanese."
        case .highQuality:
            return common + "\nTone: high-quality but still faithful to source text."
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
