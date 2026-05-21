import SwiftUI

struct ContentView: View {
    @StateObject private var store = WordStore()

    var body: some View {
        TabView {
            WordListView(store: store)
                .tabItem {
                    Label("語句", systemImage: "text.book.closed")
                }

            PracticeView(store: store)
                .tabItem {
                    Label("復習", systemImage: "checkmark.circle")
                }

            StatsView(words: store.words)
                .tabItem {
                    Label("記録", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    ContentView()
}
