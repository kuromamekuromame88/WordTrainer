import SwiftUI

struct WordDetailView: View {
    @ObservedObject var store: WordStore
    @State private var word: VocabularyWord
    @State private var showingEditor = false

    init(store: WordStore, word: VocabularyWord) {
        self.store = store
        _word = State(initialValue: word)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(word.term)
                        .font(.largeTitle.bold())

                    Text(word.meaning)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            if !word.example.isEmpty {
                Section("例文") {
                    Text(word.example)
                }
            }

            if !word.note.isEmpty {
                Section("メモ") {
                    Text(word.note)
                }
            }

            Section("習得状況") {
                Picker("状態", selection: masteryBinding) {
                    ForEach(Mastery.allCases) { mastery in
                        Text(mastery.title).tag(mastery)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("単語詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("編集") {
                showingEditor = true
            }
        }
        .sheet(isPresented: $showingEditor) {
            WordEditorView(title: "単語を編集", saveTitle: "更新", word: word) { term, meaning, example, note in
                word.term = term.trimmingCharacters(in: .whitespacesAndNewlines)
                word.meaning = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
                word.example = example.trimmingCharacters(in: .whitespacesAndNewlines)
                word.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
                store.update(word)
            }
        }
        .onReceive(store.$words) { words in
            guard let latest = words.first(where: { $0.id == word.id }) else { return }
            word = latest
        }
    }

    private var masteryBinding: Binding<Mastery> {
        Binding(
            get: { word.mastery },
            set: { newValue in
                word.mastery = newValue
                word.reviewedAt = Date()
                store.update(word)
            }
        )
    }
}
