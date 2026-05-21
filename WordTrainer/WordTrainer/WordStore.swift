import Foundation
import Combine

@MainActor
final class WordStore: ObservableObject {
    @Published private(set) var words: [VocabularyWord] = []

    private let saveURL: URL

    init(saveURL: URL? = nil) {
        if let saveURL {
            self.saveURL = saveURL
        } else {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.saveURL = documents.appendingPathComponent("words.json")
        }

        load()
    }

    func add(term: String, meaning: String, series: String, answerMode: AnswerMode, example: String, note: String) {
        let word = VocabularyWord(
            term: term.trimmingCharacters(in: .whitespacesAndNewlines),
            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines),
            series: normalizedSeries(series),
            answerMode: answerMode,
            example: example.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        words.insert(word, at: 0)
        save()
    }

    func update(_ word: VocabularyWord) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index] = word
        save()
    }

    func delete(at offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            words.remove(at: offset)
        }
        save()
    }

    func mark(_ word: VocabularyWord, as mastery: Mastery) {
        guard let index = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[index].mastery = mastery
        words[index].reviewedAt = Date()
        save()
    }

    var dueWords: [VocabularyWord] {
        dueWords(in: nil)
    }

    var seriesNames: [String] {
        Array(Set(words.map { normalizedSeries($0.series) })).sorted()
    }

    func dueWords(in series: String?) -> [VocabularyWord] {
        words
            .filter { word in
                word.mastery != .remembered
                && (series == nil || normalizedSeries(word.series) == normalizedSeries(series ?? ""))
            }
            .sorted { lhs, rhs in
                (lhs.reviewedAt ?? .distantPast) < (rhs.reviewedAt ?? .distantPast)
            }
    }

    func choiceOptions(for word: VocabularyWord, count: Int = 4) -> [String] {
        let correct = word.term
        let sameSeries = words
            .filter { $0.id != word.id && normalizedSeries($0.series) == normalizedSeries(word.series) }
            .map(\.term)

        let otherSeries = words
            .filter { $0.id != word.id && normalizedSeries($0.series) != normalizedSeries(word.series) }
            .map(\.term)

        let fallback = Self.fallbackChoices.filter { normalized($0) != normalized(correct) }
        let candidates = uniqueTerms(sameSeries + otherSeries + fallback, excluding: correct)
        return Array(([correct] + candidates.prefix(max(count - 1, 0))).shuffled())
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            words = try JSONDecoder().decode([VocabularyWord].self, from: data)
            words = words.map { word in
                var normalizedWord = word
                normalizedWord.series = normalizedSeries(word.series)
                return normalizedWord
            }
        } catch {
            words = Self.sampleWords
            save()
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(words)
            try data.write(to: saveURL, options: [.atomic])
        } catch {
            assertionFailure("Failed to save words: \(error)")
        }
    }

    private func normalizedSeries(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未分類" : trimmed
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func uniqueTerms(_ terms: [String], excluding excluded: String) -> [String] {
        var seen = Set<String>([normalized(excluded)])
        var result: [String] = []

        for term in terms {
            let key = normalized(term)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(term)
        }

        return result
    }

    static let sampleWords: [VocabularyWord] = [
        VocabularyWord(
            term: "curious",
            meaning: "好奇心の強い",
            series: "英単語",
            answerMode: .textInput,
            example: "She is curious about how apps are made.",
            note: "curiosity とセットで覚える"
        ),
        VocabularyWord(
            term: "steady",
            meaning: "着実な、安定した",
            series: "英単語",
            answerMode: .multipleChoice,
            example: "Small steady practice builds vocabulary.",
            note: ""
        ),
        VocabularyWord(
            term: "光合成",
            meaning: "植物が光のエネルギーを使って養分を作るはたらき",
            series: "理科",
            answerMode: .multipleChoice,
            example: "",
            note: "葉緑体で行われる"
        )
    ]

    private static let fallbackChoices = [
        "curious",
        "steady",
        "光合成",
        "比例",
        "鎌倉幕府",
        "主語",
        "酸素",
        "分数"
    ]
}
