import Foundation

enum FormattingMode: String, CaseIterable, Identifiable, Codable {
    case plain
    case polite
    case highQuality

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plain:
            return "プレーン整形"
        case .polite:
            return "丁寧文"
        case .highQuality:
            return "高品質整形"
        }
    }

    var detail: String {
        switch self {
        case .plain:
            return "フィラー除去 + 句読点補完"
        case .polite:
            return "プレーン整形 + 丁寧語"
        case .highQuality:
            return "Gemini 2.5 Flashで高品質整形"
        }
    }

    var modelTier: ModelTier {
        switch self {
        case .highQuality:
            return .highQuality
        case .plain, .polite:
            return .default
        }
    }
}

enum ModelTier {
    case `default`
    case highQuality
}
