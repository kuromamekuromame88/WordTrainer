import SwiftUI

struct PracticeView: View {
    @ObservedObject var store: WordStore
    @State private var selectedSeries = "すべて"
    @State private var currentIndex = 0
    @State private var answerText = ""
    @State private var checkedAnswer: CheckedAnswer?
    @State private var choiceOptions: [String] = []
    @FocusState private var isAnswerFocused: Bool

    private static let allSeriesTitle = "すべて"

    private var selectedSeriesFilter: String? {
        selectedSeries == Self.allSeriesTitle ? nil : selectedSeries
    }

    private var dueWords: [VocabularyWord] {
        store.dueWords(in: selectedSeriesFilter)
    }

    private var currentWord: VocabularyWord? {
        guard dueWords.indices.contains(currentIndex) else { return dueWords.first }
        return dueWords[currentIndex]
    }

    private var seriesOptions: [String] {
        [Self.allSeriesTitle] + store.seriesNames
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("シリーズ", selection: $selectedSeries) {
                    ForEach(seriesOptions, id: \.self) { series in
                        Text(series).tag(series)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .trailing)

                if let word = currentWord {
                    Spacer(minLength: 12)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Label(word.series, systemImage: "folder")
                            Spacer()
                            Text(word.answerMode.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text("この問題の答えは？")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(word.meaning)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .minimumScaleFactor(0.7)

                        if word.answerMode == .textInput {
                            TextField("答えを入力", text: $answerText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($isAnswerFocused)
                                .submitLabel(.done)
                                .textFieldStyle(.roundedBorder)
                                .disabled(checkedAnswer != nil)
                                .onSubmit {
                                    check(word, answer: answerText)
                                }
                        } else {
                            ChoiceGrid(
                                options: choiceOptions,
                                selectedAnswer: answerText,
                                isDisabled: checkedAnswer != nil
                            ) { option in
                                answerText = option
                                check(word, answer: option)
                            }
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
                            check(word, answer: answerText)
                        } label: {
                            Label("答え合わせ", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(word.answerMode == .multipleChoice || normalized(answerText).isEmpty)
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
                        "復習する語句がありません",
                        systemImage: "sparkles",
                        description: Text("新しい語句を追加するか、覚えた語句の状態を変更すると復習できます。")
                    )
                }
            }
            .padding()
            .navigationTitle("復習")
            .onAppear {
                prepareQuestion()
            }
            .onChange(of: selectedSeries) { _, _ in
                currentIndex = 0
                prepareQuestion()
            }
            .onChange(of: currentWord?.id) { _, _ in
                prepareQuestion()
            }
        }
    }

    private func check(_ word: VocabularyWord, answer: String) {
        let userAnswer = normalized(answer)
        guard !userAnswer.isEmpty else { return }

        let correctAnswer = normalized(word.term)
        let isCorrect = userAnswer == correctAnswer

        withAnimation(.snappy) {
            checkedAnswer = CheckedAnswer(input: answer, isCorrect: isCorrect)
        }
    }

    private func rate(_ word: VocabularyWord, as mastery: Mastery) {
        store.mark(word, as: mastery)
        moveToNextQuestion()
    }

    private func moveToNextQuestion() {
        if currentIndex >= dueWords.count {
            currentIndex = 0
        }
        prepareQuestion()
    }

    private func prepareQuestion() {
        answerText = ""
        checkedAnswer = nil

        if let word = currentWord {
            choiceOptions = store.choiceOptions(for: word)
            isAnswerFocused = word.answerMode == .textInput
        } else {
            choiceOptions = []
            isAnswerFocused = false
        }
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private struct CheckedAnswer: Equatable {
    let input: String
    let isCorrect: Bool
}

private struct ChoiceGrid: View {
    let options: [String]
    let selectedAnswer: String
    let isDisabled: Bool
    let onSelect: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    Text(option)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .disabled(isDisabled)
                .tint(selectedAnswer == option ? .accentColor : nil)
            }
        }
    }
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
