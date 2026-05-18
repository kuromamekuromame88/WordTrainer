import SwiftUI

struct PracticeView: View {
    @ObservedObject var store: WordStore
    @State private var currentIndex = 0
    @State private var showingAnswer = false

    private var dueWords: [VocabularyWord] {
        store.dueWords
    }

    private var currentWord: VocabularyWord? {
        guard dueWords.indices.contains(currentIndex) else { return dueWords.first }
        return dueWords[currentIndex]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let word = currentWord {
                    Spacer(minLength: 20)

                    VStack(spacing: 16) {
                        Text(word.term)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)

                        if showingAnswer {
                            VStack(spacing: 10) {
                                Text(word.meaning)
                                    .font(.title3)

                                if !word.example.isEmpty {
                                    Text(word.example)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)

                    Spacer()

                    if showingAnswer {
                        HStack(spacing: 12) {
                            Button {
                                rate(word, as: .learning)
                            } label: {
                                Label("もう一度", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                rate(word, as: .remembered)
                            } label: {
                                Label("覚えた", systemImage: "checkmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Button {
                            withAnimation(.snappy) {
                                showingAnswer = true
                            }
                        } label: {
                            Label("答えを見る", systemImage: "eye")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView(
                        "復習する単語がありません",
                        systemImage: "sparkles",
                        description: Text("新しい単語を追加するか、覚えた単語の状態を変更すると復習できます。")
                    )
                }
            }
            .padding()
            .navigationTitle("復習")
        }
    }

    private func rate(_ word: VocabularyWord, as mastery: Mastery) {
        store.mark(word, as: mastery)
        showingAnswer = false
        if currentIndex >= max(dueWords.count - 1, 0) {
            currentIndex = 0
        }
    }
}
