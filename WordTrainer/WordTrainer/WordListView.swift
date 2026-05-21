import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct WordListView: View {
    @ObservedObject var store: WordStore
    @State private var searchText = ""
    @State private var showingAddWord = false
    @State private var selectedSeries = "すべて"
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument = VocabularyJSONDocument(words: [])
    @State private var importMessage: String?

    private static let allSeriesTitle = "すべて"

    private var selectedSeriesFilter: String? {
        selectedSeries == Self.allSeriesTitle ? nil : selectedSeries
    }

    private var seriesOptions: [String] {
        [Self.allSeriesTitle] + store.seriesNames
    }

    private var seriesFilteredWords: [VocabularyWord] {
        store.words(in: selectedSeriesFilter)
    }

    private var filteredWords: [VocabularyWord] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return seriesFilteredWords
        }

        return seriesFilteredWords.filter {
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
                Section {
                    Picker("表示シリーズ", selection: $selectedSeries) {
                        ForEach(seriesOptions, id: \.self) { series in
                            Text(series).tag(series)
                        }
                    }
                }

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
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            prepareExport()
                        } label: {
                            Label("JSONを書き出す", systemImage: "square.and.arrow.up")
                        }
                        .disabled(store.exportWords(in: selectedSeriesFilter).isEmpty)

                        Button {
                            isImporting = true
                        } label: {
                            Label("JSONを読み込む", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("読み込みと書き出し")
                }

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
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: exportFilename
            ) { result in
                if case .failure(let error) = result {
                    importMessage = "書き出しに失敗しました: \(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                importJSON(from: result)
            }
            .alert("JSON", isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    private var exportFilename: String {
        let baseName = selectedSeries == Self.allSeriesTitle ? "all-series" : selectedSeries
        let safeName = baseName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return "\(safeName)-questions.json"
    }

    private func prepareExport() {
        exportDocument = VocabularyJSONDocument(words: store.exportWords(in: selectedSeriesFilter))
        isExporting = true
    }

    private func importJSON(from result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let count = try store.importWords(from: data)
            importMessage = "\(count)件の語句を読み込みました。"
        } catch {
            importMessage = "読み込みに失敗しました: \(error.localizedDescription)"
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

struct VocabularyJSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(words: [VocabularyWord]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        data = (try? encoder.encode(words)) ?? Data("[]".utf8)
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
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
