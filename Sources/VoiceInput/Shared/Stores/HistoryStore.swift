import Foundation
import Combine

@MainActor
final class HistoryStore: ObservableObject {
    struct Entry: Codable, Identifiable {
        let id: UUID
        let createdAt: Date
        let mode: FormattingMode
        let rawText: String
        let cleanedText: String
    }

    private let defaults: UserDefaults
    private let key = "history.entries"
    @Published var entries: [Entry] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.entries = loadEntries()
    }

    func append(raw: String, cleaned: String, mode: FormattingMode) {
        let entry = Entry(id: UUID(), createdAt: Date(), mode: mode, rawText: raw, cleanedText: cleaned)
        entries.insert(entry, at: 0)
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }
        persistEntries()
    }

    private func persistEntries() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }

    private func loadEntries() -> [Entry] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return decoded
    }
}
