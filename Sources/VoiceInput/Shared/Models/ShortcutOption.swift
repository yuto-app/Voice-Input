import Foundation

enum ShortcutOption: String, CaseIterable, Identifiable {
    case fnHold
    case optionSpaceHold
    case controlSpaceHold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fnHold:
            return "Fn (推奨候補)"
        case .optionSpaceHold:
            return "Option + Space"
        case .controlSpaceHold:
            return "Control + Space"
        }
    }

    var summary: String {
        switch self {
        case .fnHold:
            return "押している間だけ録音"
        case .optionSpaceHold, .controlSpaceHold:
            return "キー押下中録音 / 離して確定"
        }
    }

    var conflictHint: String? {
        switch self {
        case .fnHold:
            return "環境によってはDictationやIME操作と競合する可能性があります。"
        case .optionSpaceHold:
            return "入力ソース切替ショートカットと競合する場合があります。"
        case .controlSpaceHold:
            return "SpotlightやIME設定と競合する場合があります。"
        }
    }
}
