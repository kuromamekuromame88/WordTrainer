import SwiftUI

struct WordListView: View {
    @ObservedObject var store: WordStore
    @State private var searchText = ""
    @State private var showingAddWord = false

    private var filteredWords: [VocabularyWord] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return store.words
        }

        return store.words.filter {
            $0.term.localizedCaseInsensitiveContains(searchText)
            || $0.meaning.localizedCaseInsensitiveContains(searchText)
            || $0.series.localizedCaseInsensitiveContains(searchText)
            || $0.example.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var groupedWords: [(series: String, words: [VocabularyWord])] {
        Dictionary(grouping: filteredWords, by: { $0.series })
            .map { (series: $0.key, words: $0.value) }
            .sorted { $0.series < $1.series }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredWords.isEmpty {
                    ContentUnavailableView(
                        "語句がありません",
                        systemImage: "square.and.pencil",
                        description: Text("右上の追加ボタンから、覚えたい語句を登録できます。")
                    )
                } else {
                    ForEach(groupedWords, id: \.series) { group in
                        Section(group.series) {
                            ForEach(group.words) { word in
                                NavigationLink {
                                    WordDetailView(store: store, word: word)
                                } label: {
                                    WordRow(word: word)
                                }
                            }
                            .onDelete { offsets in
                                delete(from: group.words, at: offsets)
                            }
                        }
                    }
                }
            }
            .navigationTitle("語句")
            .searchable(text: $searchText, prompt: "語句・問題文・シリーズを検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddWord = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("語句を追加")
                }
            }
            .sheet(isPresented: $showingAddWord) {
                WordEditorView { term, meaning, series, answerMode, example, note in
                    store.add(term: term, meaning: meaning, series: series, answerMode: answerMode, example: example, note: note)
                }
            }
        }
    }

    private func delete(from words: [VocabularyWord], at offsets: IndexSet) {
        let ids = offsets.map { words[$0].id }
        var storeOffsets = IndexSet()
        for id in ids {
            if let index = store.words.firstIndex(where: { $0.id == id }) {
                storeOffsets.insert(index)
            }
        }
        store.delete(at: storeOffsets)
    }
}

struct WordRow: View {
    let word: VocabularyWord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(word.term)
                    .font(.headline)
                Spacer()
                Text(word.mastery.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }

            Text(word.meaning)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label(word.series, systemImage: "folder")
                Label(word.answerMode.title, systemImage: word.answerMode == .textInput ? "keyboard" : "list.bullet.rectangle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !word.example.isEmpty {
                Text(word.example)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
