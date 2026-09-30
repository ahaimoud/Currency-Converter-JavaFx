//
//  Flashcard.swift
//  Core data models shared across the app.
//

import Foundation

/// A single term/definition pair.
struct Flashcard: Identifiable, Hashable {
    let id = UUID()
    let term: String
    let definition: String
}

/// Which side of the card is shown as the prompt.
enum QuizDirection: String, CaseIterable, Identifiable {
    case termToDefinition = "Term → Definition"
    case definitionToTerm = "Definition → Term"
    var id: String { rawValue }
}

/// How the user answers.
enum QuizFormat: String, CaseIterable, Identifiable {
    case multipleChoice = "Multiple choice"
    case typed = "Type answer"
    var id: String { rawValue }
}

/// One prepared quiz question.
struct QuizQuestion: Identifiable {
    let id = UUID()
    let card: Flashcard
    let prompt: String
    let answer: String
    /// Shuffled options (only used for multiple choice).
    let choices: [String]
}

extension Flashcard {
    /// Small built-in deck so the app can be tried without importing a file.
    static let sampleDeck: [Flashcard] = [
        ("Mitochondria", "The organelle that produces most of a cell's ATP"),
        ("Photosynthesis", "Process by which plants convert light energy into chemical energy"),
        ("Osmosis", "Diffusion of water across a semipermeable membrane"),
        ("Ribosome", "Cell structure where proteins are synthesized"),
        ("Nucleus", "Organelle that contains the cell's DNA"),
        ("Enzyme", "A protein that speeds up a chemical reaction"),
    ].map { Flashcard(term: $0.0, definition: $0.1) }
}
