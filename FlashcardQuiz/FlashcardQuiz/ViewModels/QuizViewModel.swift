//
//  QuizViewModel.swift
//  Holds quiz settings, builds questions, grades answers and tracks progress.
//

import Foundation
import SwiftUI

@MainActor
final class QuizViewModel: ObservableObject {

    enum Phase { case setup, quiz, results }

    // MARK: Settings (chosen on the setup screen)
    @Published var direction: QuizDirection = .termToDefinition
    @Published var format: QuizFormat = .multipleChoice
    @Published var shuffle = true

    // MARK: Quiz state
    @Published private(set) var phase: Phase = .setup
    @Published private(set) var questions: [QuizQuestion] = []
    @Published private(set) var index = 0
    @Published private(set) var score = 0
    @Published private(set) var missed: [Flashcard] = []

    // Per-question state
    @Published var typedAnswer = ""
    @Published private(set) var selectedChoice: String?
    @Published private(set) var hasAnswered = false
    @Published private(set) var lastWasCorrect = false

    let deck: [Flashcard]

    init(deck: [Flashcard]) {
        self.deck = deck
    }

    // MARK: Derived values
    var current: QuizQuestion? { questions.indices.contains(index) ? questions[index] : nil }
    var total: Int { questions.count }
    /// 0...1 progress through the quiz (counts the current question once answered).
    var progress: Double {
        total == 0 ? 0 : Double(index + (hasAnswered ? 1 : 0)) / Double(total)
    }
    var percentage: Int { total == 0 ? 0 : Int((Double(score) / Double(total) * 100).rounded()) }
    var canUseMultipleChoice: Bool { deck.count >= 2 }
    var isLastQuestion: Bool { index >= total - 1 }

    // MARK: Lifecycle

    func start() { begin(with: deck) }

    /// Re-quiz only the cards answered incorrectly.
    func retryMissed() { begin(with: missed) }

    func restart() {
        phase = .setup
    }

    private func begin(with cards: [Flashcard]) {
        if !canUseMultipleChoice { format = .typed }
        let ordered = shuffle ? cards.shuffled() : cards
        questions = ordered.map(makeQuestion)
        index = 0
        score = 0
        missed = []
        resetQuestionState()
        phase = .quiz
    }

    private func makeQuestion(for card: Flashcard) -> QuizQuestion {
        let fromTerm = direction == .termToDefinition
        let prompt = fromTerm ? card.term : card.definition
        let answer = fromTerm ? card.definition : card.term

        var choices: [String] = []
        if format == .multipleChoice {
            // Distractors come from the whole deck, not just the cards in this round.
            let pool = deck
                .map { fromTerm ? $0.definition : $0.term }
                .filter { $0 != answer }
            let distractors = Array(Set(pool)).shuffled().prefix(3)
            choices = (Array(distractors) + [answer]).shuffled()
        }
        return QuizQuestion(card: card, prompt: prompt, answer: answer, choices: choices)
    }

    // MARK: Answering

    func submitChoice(_ choice: String) {
        guard !hasAnswered, let q = current else { return }
        selectedChoice = choice
        grade(correct: choice == q.answer)
    }

    func submitTyped() {
        guard !hasAnswered, let q = current else { return }
        grade(correct: Self.normalize(typedAnswer) == Self.normalize(q.answer))
    }

    /// Lets the user override a typed answer that was marked wrong (e.g. a typo).
    func markTypedAsCorrect() {
        guard hasAnswered, !lastWasCorrect, let q = current else { return }
        missed.removeAll { $0.id == q.card.id }
        score += 1
        lastWasCorrect = true
    }

    private func grade(correct: Bool) {
        hasAnswered = true
        lastWasCorrect = correct
        if correct {
            score += 1
        } else if let q = current {
            missed.append(q.card)
        }
    }

    func next() {
        if isLastQuestion {
            phase = .results
        } else {
            index += 1
            resetQuestionState()
        }
    }

    private func resetQuestionState() {
        typedAnswer = ""
        selectedChoice = nil
        hasAnswered = false
        lastWasCorrect = false
    }

    // MARK: Answer normalisation

    /// Case-, diacritic-, whitespace- and trailing-punctuation-insensitive comparison key.
    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let collapsed = folded
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?"))
    }
}
