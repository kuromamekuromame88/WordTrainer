import SwiftUI

struct StatsView: View {
    let words: [VocabularyWord]

    private var total: Int { words.count }
    private var newCount: Int { words.filter { $0.mastery == .new }.count }
    private var learningCount: Int { words.filter { $0.mastery == .learning }.count }
    private var rememberedCount: Int { words.filter { $0.mastery == .remembered }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatRow(title: "登録単語", value: total, systemImage: "text.book.closed")
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
