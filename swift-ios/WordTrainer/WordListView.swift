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
            || $0.example.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredWords.isEmpty {
                    ContentUnavailableView(
                        "単語がありません",
                        systemImage: "square.and.pencil",
                        description: Text("右上の追加ボタンから、覚えたい英単語を登録できます。")
                    )
                } else {
                    ForEach(filteredWords) { word in
                        NavigationLink {
                            WordDetailView(store: store, word: word)
                        } label: {
                            WordRow(word: word)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("英単語")
            .searchable(text: $searchText, prompt: "単語・意味・例文を検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddWord = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("単語を追加")
                }
            }
            .sheet(isPresented: $showingAddWord) {
                WordEditorView { term, meaning, example, note in
                    store.add(term: term, meaning: meaning, example: example, note: note)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { filteredWords[$0].id }
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
