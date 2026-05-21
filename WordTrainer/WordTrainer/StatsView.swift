import SwiftUI

struct StatsView: View {
    let words: [VocabularyWord]

    private var total: Int { words.count }
    private var newCount: Int { words.filter { $0.mastery == .new }.count }
    private var learningCount: Int { words.filter { $0.mastery == .learning }.count }
    private var rememberedCount: Int { words.filter { $0.mastery == .remembered }.count }
    private var groupedWords: [(series: String, count: Int)] {
        Dictionary(grouping: words, by: { $0.series })
            .map { (series: $0.key, count: $0.value.count) }
            .sorted { $0.series < $1.series }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatRow(title: "登録語句", value: total, systemImage: "text.book.closed")
                    StatRow(title: "未学習", value: newCount, systemImage: "circle")
                    StatRow(title: "学習中", value: learningCount, systemImage: "pencil.circle")
                    StatRow(title: "覚えた", value: rememberedCount, systemImage: "checkmark.circle")
                }

                Section("進捗") {
                    ProgressView(value: total == 0 ? 0 : Double(rememberedCount) / Double(total)) {
                        Text("暗記率")
                    } currentValueLabel: {
                        Text("\(progressPercent)%")
                    }
                }

                if !groupedWords.isEmpty {
                    Section("シリーズ") {
                        ForEach(groupedWords, id: \.series) { group in
                            StatRow(title: group.series, value: group.count, systemImage: "folder")
                        }
                    }
                }
            }
            .navigationTitle("記録")
        }
    }

    private var progressPercent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(rememberedCount) / Double(total) * 100).rounded())
    }
}

struct StatRow: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text(value.formatted())
                .font(.headline)
        }
    }
}
