import Foundation

struct VocabularyWord: Identifiable, Codable, Equatable {
    var id: UUID
    var term: String
    var meaning: String
    var example: String
    var note: String
    var mastery: Mastery
    var createdAt: Date
    var reviewedAt: Date?

    init(
        id: UUID = UUID(),
        term: String,
        meaning: String,
        example: String = "",
        note: String = "",
        mastery: Mastery = .new,
        createdAt: Date = Date(),
        reviewedAt: Date? = nil
    ) {
        self.id = id
        self.term = term
        self.meaning = meaning
        self.example = example
        self.note = note
        self.mastery = mastery
        self.createdAt = createdAt
        self.reviewedAt = reviewedAt
    }
}

enum Mastery: String, CaseIterable, Codable, Identifiable {
    case new
    case learning
    case remembered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new:
            return "未学習"
        case .learning:
            return "学習中"
        case .remembered:
            return "覚えた"
        }
    }
}
