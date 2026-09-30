//
//  ResultsView.swift
//  End-of-quiz summary: score ring, percentage, missed cards, and next actions.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var vm: QuizViewModel

    private var message: String {
        switch vm.percentage {
        case 100:      return "Perfect score! 🎉"
        case 80...99:  return "Great job!"
        case 50...79:  return "Good effort — keep practicing."
        default:       return "Keep at it — you'll get there."
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 14)
                        Circle()
                            .trim(from: 0, to: Double(vm.percentage) / 100)
                            .stroke(Color.accentColor,
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text("\(vm.percentage)%").font(.largeTitle.bold())
                            Text("\(vm.score) / \(vm.total)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 160, height: 160)
                    .padding(.top, 8)

                    Text(message).font(.headline)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                if !vm.missed.isEmpty {
                    Button {
                        vm.retryMissed()
                    } label: {
                        Label("Retry \(vm.missed.count) missed", systemImage: "arrow.counterclockwise")
                    }
                }
                Button {
                    vm.start()
                } label: {
                    Label("Restart quiz", systemImage: "arrow.clockwise")
                }
                Button {
                    vm.restart()
                } label: {
                    Label("Change settings", systemImage: "slider.horizontal.3")
                }
            }

            if !vm.missed.isEmpty {
                Section("Review missed cards") {
                    ForEach(vm.missed) { card in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.term).font(.headline)
                            Text(card.definition)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
