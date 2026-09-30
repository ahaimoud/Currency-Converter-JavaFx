//
//  QuizContainerView.swift
//  Owns the QuizViewModel and switches between setup → quiz → results.
//

import SwiftUI

struct QuizContainerView: View {
    @StateObject private var vm: QuizViewModel
    let deckName: String

    init(deck: [Flashcard], deckName: String) {
        _vm = StateObject(wrappedValue: QuizViewModel(deck: deck))
        self.deckName = deckName
    }

    var body: some View {
        Group {
            switch vm.phase {
            case .setup:   QuizSetupView(vm: vm)
            case .quiz:    QuizView(vm: vm)
            case .results: ResultsView(vm: vm)
            }
        }
        .navigationTitle(deckName)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: vm.phase)
    }
}

// MARK: - Setup

struct QuizSetupView: View {
    @ObservedObject var vm: QuizViewModel

    var body: some View {
        Form {
            Section("Show me") {
                Picker("Direction", selection: $vm.direction) {
                    ForEach(QuizDirection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            Section("Answer by") {
                Picker("Format", selection: $vm.format) {
                    ForEach(QuizFormat.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                if !vm.canUseMultipleChoice {
                    Text("Multiple choice needs at least 2 cards; typing will be used.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Toggle("Shuffle cards", isOn: $vm.shuffle)
            }

            Section {
                Button {
                    vm.start()
                } label: {
                    Text("Begin (\(vm.deck.count) questions)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowBackground(Color.clear)
            }
        }
    }
}
