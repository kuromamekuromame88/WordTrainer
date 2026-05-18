import SwiftUI

struct WordEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var term: String
    @State private var meaning: String
    @State private var example: String
    @State private var note: String

    let title: String
    let saveTitle: String
    let onSave: (String, String, String, String) -> Void

    init(
        title: String = "単語を追加",
        saveTitle: String = "保存",
        word: VocabularyWord? = nil,
        onSave: @escaping (String, String, String, String) -> Void
    ) {
        self.title = title
        self.saveTitle = saveTitle
        self.onSave = onSave
        _term = State(initialValue: word?.term ?? "")
        _meaning = State(initialValue: word?.meaning ?? "")
        _example = State(initialValue: word?.example ?? "")
        _note = State(initialValue: word?.note ?? "")
    }

    private var canSave: Bool {
        !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("必須") {
                    TextField("英単語", text: $term)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("意味", text: $meaning)
                }

                Section("任意") {
                    TextField("例文", text: $example, axis: .vertical)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.never)

                    TextField("メモ", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveTitle) {
                        onSave(term, meaning, example, note)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
