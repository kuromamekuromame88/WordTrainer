import SwiftUI

struct PracticeView: View {
    @ObservedObject var store: WordStore
    @State private var currentIndex = 0
    @State private var answerText = ""
    @State private var checkedAnswer: CheckedAnswer?
    @FocusState private var isAnswerFocused: Bool

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
                    Spacer(minLength: 12)

                    VStack(alignment: .leading, spacing: 18) {
                        Text("この意味の英単語は？")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(word.meaning)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .minimumScaleFactor(0.7)

                        TextField("英単語を入力", text: $answerText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isAnswerFocused)
                            .submitLabel(.done)
                            .textFieldStyle(.roundedBorder)
                            .disabled(checkedAnswer != nil)
                            .onSubmit {
                                check(word)
                            }

                        if let checkedAnswer {
                            ResultPanel(result: checkedAnswer, word: word)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)

                    Spacer()

                    if checkedAnswer == nil {
                        Button {
                            check(word)
                        } label: {
                            Label("答え合わせ", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(normalized(answerText).isEmpty)
                    } else {
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
            .onChange(of: currentWord?.id) { _, _ in
                resetAnswer()
            }
            .onAppear {
                isAnswerFocused = currentWord != nil
            }
        }
    }

    private func check(_ word: VocabularyWord) {
        let userAnswer = normalized(answerText)
        guard !userAnswer.isEmpty else { return }

        let correctAnswer = normalized(word.term)
        let isCorrect = userAnswer == correctAnswer

        withAnimation(.snappy) {
            checkedAnswer = CheckedAnswer(input: answerText, isCorrect: isCorrect)
        }
    }

    private func rate(_ word: VocabularyWord, as mastery: Mastery) {
        store.mark(word, as: mastery)
        moveToNextQuestion()
    }

    private func moveToNextQuestion() {
        resetAnswer()
        if currentIndex >= max(dueWords.count - 1, 0) {
            currentIndex = 0
        }
        isAnswerFocused = currentWord != nil
    }

    private func resetAnswer() {
        answerText = ""
        checkedAnswer = nil
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private struct CheckedAnswer: Equatable {
    let input: String
    let isCorrect: Bool
}

private struct ResultPanel: View {
    let result: CheckedAnswer
    let word: VocabularyWord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(result.isCorrect ? "正解です" : "答えを確認しましょう", systemImage: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(result.isCorrect ? .green : .red)

            HStack {
                Text("入力")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(result.input)
                    .font(.body)
            }

            HStack {
                Text("正解")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(word.term)
                    .font(.headline)
            }

            if !word.example.isEmpty {
                Text(word.example)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
