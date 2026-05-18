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

    func add(term: String, meaning: String, example: String, note: String) {
        let word = VocabularyWord(
            term: term.trimmingCharacters(in: .whitespacesAndNewlines),
            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines),
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
        words
            .filter { $0.mastery != .remembered }
            .sorted { lhs, rhs in
                (lhs.reviewedAt ?? .distantPast) < (rhs.reviewedAt ?? .distantPast)
            }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: saveURL)
            words = try JSONDecoder().decode([VocabularyWord].self, from: data)
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

    static let sampleWords: [VocabularyWord] = [
        VocabularyWord(
            term: "curious",
            meaning: "好奇心の強い",
            example: "She is curious about how apps are made.",
            note: "curiosity とセットで覚える"
        ),
        VocabularyWord(
            term: "steady",
            meaning: "着実な、安定した",
            example: "Small steady practice builds vocabulary.",
            note: ""
        )
    ]
}
