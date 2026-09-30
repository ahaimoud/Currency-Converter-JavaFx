//
//  ContentView.swift
//  Home screen: import a CSV/XLSX file (or load the sample deck), preview the
//  cards, then start a quiz.
//

import SwiftUI

struct ContentView: View {
    @State private var deck: [Flashcard] = []
    @State private var deckName = ""
    @State private var showImporter = false
    @State private var errorMessage: String?
    @State private var showQuiz = false

    var body: some View {
        NavigationStack {
            Group {
                if deck.isEmpty {
                    emptyState
                } else {
                    deckList
                }
            }
            .navigationTitle("Flashcard Quiz")
            .toolbar {
                if !deck.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showImporter = true
                        } label: {
                            Label("Import", systemImage: "square.and.arrow.down")
                        }
                    }
                }
            }
            // Document picker (Files app, iCloud Drive, etc.)
            .fileImporter(isPresented: $showImporter,
                          allowedContentTypes: FileImporter.allowedTypes,
                          allowsMultipleSelection: false) { result in
                handleImport(result)
            }
            .alert("Import Failed",
                   isPresented: Binding(get: { errorMessage != nil },
                                        set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .navigationDestination(isPresented: $showQuiz) {
                QuizContainerView(deck: deck, deckName: deckName)
            }
        }
    }

    // MARK: Subviews

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Import your flashcards")
                .font(.title2.bold())
            Text("Choose a CSV or Excel (.xlsx) file with terms in the first column and definitions in the second.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                showImporter = true
            } label: {
                Label("Import File", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Try the sample deck") {
                deck = Flashcard.sampleDeck
                deckName = "Sample: Biology"
            }
        }
        .padding(32)
    }

    private var deckList: some View {
        List {
            Section {
                Button {
                    showQuiz = true
                } label: {
                    Label("Start Quiz (\(deck.count) cards)", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color.clear)
            }

            Section("\(deckName) · \(deck.count) cards") {
                ForEach(deck) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.term).font(.headline)
                        Text(card.definition)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: Import handling

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                deck = try FileImporter.loadCards(from: url)
                deckName = url.deletingPathExtension().lastPathComponent
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ContentView()
}
