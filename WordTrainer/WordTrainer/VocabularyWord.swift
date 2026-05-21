import Foundation

struct VocabularyWord: Identifiable, Codable, Equatable {
    var id: UUID
    var term: String
    var meaning: String
    var series: String
    var answerMode: AnswerMode
    var example: String
    var note: String
    var mastery: Mastery
    var createdAt: Date
    var reviewedAt: Date?

    init(
        id: UUID = UUID(),
        term: String,
        meaning: String,
        series: String = "英単語",
        answerMode: AnswerMode = .textInput,
        example: String = "",
        note: String = "",
        mastery: Mastery = .new,
        createdAt: Date = Date(),
        reviewedAt: Date? = nil
    ) {
        self.id = id
        self.term = term
        self.meaning = meaning
        self.series = series
        self.answerMode = answerMode
        self.example = example
        self.note = note
        self.mastery = mastery
        self.createdAt = createdAt
        self.reviewedAt = reviewedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case term
        case meaning
        case series
        case answerMode
        case example
        case note
        case mastery
        case createdAt
        case reviewedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        term = try container.decode(String.self, forKey: .term)
        meaning = try container.decode(String.self, forKey: .meaning)
        series = try container.decodeIfPresent(String.self, forKey: .series) ?? "英単語"
        answerMode = try container.decodeIfPresent(AnswerMode.self, forKey: .answerMode) ?? .textInput
        example = try container.decodeIfPresent(String.self, forKey: .example) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        mastery = try container.decodeIfPresent(Mastery.self, forKey: .mastery) ?? .new
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        reviewedAt = try container.decodeIfPresent(Date.self, forKey: .reviewedAt)
    }
}

enum AnswerMode: String, CaseIterable, Codable, Identifiable {
    case textInput
    case multipleChoice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .textInput:
            return "手入力"
        case .multipleChoice:
            return "選択式"
        }
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
