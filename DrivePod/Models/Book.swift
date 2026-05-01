import Foundation

struct Book: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let author: String
    let coverEmoji: String
    let category: String
    let totalDurationMinutes: Int
    let summaryTagline: String
    let chapters: [Chapter]
}

struct Chapter: Identifiable, Codable, Hashable {
    let id: String
    let number: Int
    let title: String
    let estimatedDurationMinutes: Int
    let keyTakeaway: String
    let summary: String
}

extension Book {
    var totalChapters: Int { chapters.count }

    func chapter(after current: Chapter) -> Chapter? {
        guard let idx = chapters.firstIndex(of: current), idx + 1 < chapters.count else { return nil }
        return chapters[idx + 1]
    }

    func chapter(before current: Chapter) -> Chapter? {
        guard let idx = chapters.firstIndex(of: current), idx > 0 else { return nil }
        return chapters[idx - 1]
    }
}
