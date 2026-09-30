//
//  QuizView.swift
//  The active quiz screen: progress bar, live score, prompt card, and either
//  multiple-choice buttons or a text field.
//

import SwiftUI

struct QuizView: View {
    @ObservedObject var vm: QuizViewModel
    @FocusState private var typingFocused: Bool

    var body: some View {
        if let q = vm.current {
            VStack(spacing: 16) {
                header

                ScrollView {
                    VStack(spacing: 20) {
                        promptCard(q)

                        if vm.format == .multipleChoice {
                            choices(for: q)
                        } else {
                            typedInput(for: q)
                        }

                        if vm.hasAnswered { feedback(for: q) }
                    }
                    .padding(.horizontal)
                }

                if vm.hasAnswered {
                    Button {
                        vm.next()
                    } label: {
                        Text(vm.isLastQuestion ? "See Results" : "Next")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .onChange(of: vm.index) { _ in typingFocused = (vm.format == .typed) }
        }
    }

    // MARK: Header (progress + score)

    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Question \(vm.index + 1) of \(vm.total)")
                Spacer()
                Label("\(vm.score)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .font(.subheadline.weight(.medium))
            ProgressView(value: vm.progress)
        }
        .padding([.horizontal, .top])
    }

    // MARK: Prompt

    private func promptCard(_ q: QuizQuestion) -> some View {
        VStack(spacing: 8) {
            Text(vm.direction == .termToDefinition ? "TERM" : "DEFINITION")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(q.prompt)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    // MARK: Multiple choice

    private func choices(for q: QuizQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(q.choices, id: \.self) { choice in
                Button {
                    vm.submitChoice(choice)
                } label: {
                    Text(choice)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(background(for: choice, in: q)))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(border(for: choice, in: q), lineWidth: 2))
                        .foregroundStyle(.primary)
                }
                .disabled(vm.hasAnswered)
            }
        }
    }

    private func background(for choice: String, in q: QuizQuestion) -> Color {
        guard vm.hasAnswered else { return Color(.secondarySystemBackground) }
        if choice == q.answer { return .green.opacity(0.25) }
        if choice == vm.selectedChoice { return .red.opacity(0.25) }
        return Color(.secondarySystemBackground)
    }

    private func border(for choice: String, in q: QuizQuestion) -> Color {
        guard vm.hasAnswered else { return .clear }
        if choice == q.answer { return .green }
        if choice == vm.selectedChoice { return .red }
        return .clear
    }

    // MARK: Typed answer

    private func typedInput(for q: QuizQuestion) -> some View {
        VStack(spacing: 10) {
            TextField("Type your answer", text: $vm.typedAnswer, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($typingFocused)
                .disabled(vm.hasAnswered)
                .submitLabel(.done)
                .onSubmit { vm.submitTyped() }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !vm.hasAnswered {
                Button("Check Answer") { vm.submitTyped() }
                    .buttonStyle(.bordered)
                    .disabled(vm.typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: Feedback

    private func feedback(for q: QuizQuestion) -> some View {
        VStack(spacing: 8) {
            Label(vm.lastWasCorrect ? "Correct!" : "Not quite",
                  systemImage: vm.lastWasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(vm.lastWasCorrect ? .green : .red)

            if !vm.lastWasCorrect {
                Text("Correct answer: \(q.answer)")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                if vm.format == .typed {
                    Button("I was right (count it)") { vm.markTypedAsCorrect() }
                        .font(.footnote)
                }
            }
        }
    }
}
