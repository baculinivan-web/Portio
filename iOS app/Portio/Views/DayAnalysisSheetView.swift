import SwiftUI
import UIKit

struct DayAnalysisSheetView: View {
    @ObservedObject var viewModel: DayAnalysisViewModel
    let context: DayAnalysisContext

    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var thinkingHapticsTask: Task<Void, Never>?
    @FocusState private var isQuestionFocused: Bool

    private var canSend: Bool {
        !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.status.isLoading
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryBlock

                        if !viewModel.messages.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    DayAnalysisMessageView(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.top, 6)
                        }

                        if viewModel.status.isLoading {
                            HStack(spacing: 10) {
                                ProgressView()
                                    .controlSize(.small)
                                Text(viewModel.result == nil ? "Analysing" : "Thinking")
                                    .font(.system(.headline, design: .rounded).weight(.semibold))
                                    .contentTransition(.numericText())
                            }
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        }

                        if case .failed(let message) = viewModel.status {
                            Button {
                                viewModel.retry(context: context)
                            } label: {
                                Text(message.isEmpty ? "Try again" : message)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.leading)
                                    .contentTransition(.numericText())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 120)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    guard let lastMessage = viewModel.messages.last else { return }
                    withAnimation(.snappy(duration: 0.25)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay(alignment: .bottom) {
                promptBox
            }
            .onAppear {
                viewModel.loadIfNeeded(context: context)
                updateThinkingHaptics(isThinking: viewModel.status.isLoading)
            }
            .onChange(of: viewModel.status.isLoading) { _, isThinking in
                updateThinkingHaptics(isThinking: isThinking)
            }
            .onDisappear {
                stopThinkingHaptics()
            }
        }
    }

    @ViewBuilder
    private var summaryBlock: some View {
        if let result = viewModel.result {
            VStack(alignment: .leading, spacing: 14) {
                Text(result.summary)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .lineSpacing(2)
                    .contentTransition(.numericText())

                if !result.avoid.isEmpty {
                    Text(result.avoid)
                        .font(.system(size: 23, weight: .medium, design: .rounded))
                        .lineSpacing(2)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                if !result.replacement.isEmpty {
                    Text(result.replacement)
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .lineSpacing(2)
                        .contentTransition(.numericText())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Tap the card to run AI analysis.")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text("It uses today's food, calories, nutrients, and your goal.")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var promptBox: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Ask about today's food", text: $question, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isQuestionFocused)
                    .submitLabel(.send)
                    .onSubmit(sendQuestion)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .frame(minHeight: 34)
                    .padding(.leading, 18)
                    .padding(.trailing, 18)
                    .padding(.vertical, 12)
                    .glassEffect(
                        .regular.tint(.clear).interactive(),
                        in: .rect(cornerRadius: 29, style: .continuous)
                    )
                    .containerShape(
                        RoundedRectangle(cornerRadius: 29, style: .continuous)
                    )

                Button(action: sendQuestion) {
                    ZStack {
                        Circle()
                            .fill(.clear)
                        Image(systemName: viewModel.status.isLoading ? "hourglass" : "arrow.up")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .frame(width: 58, height: 58)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .opacity(canSend || viewModel.status.isLoading ? 1 : 0.45)
                .accessibilityLabel("Send AI question")
                .glassEffect(.regular.tint(.clear).interactive(), in: ContainerRelativeShape())
                .containerShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    private func sendQuestion() {
        guard canSend else { return }
        let currentQuestion = question
        question = ""
        viewModel.ask(currentQuestion, context: context)
    }

    private func updateThinkingHaptics(isThinking: Bool) {
        if isThinking {
            startThinkingHaptics()
        } else {
            stopThinkingHaptics()
        }
    }

    private func startThinkingHaptics() {
        guard thinkingHapticsTask == nil else { return }

        thinkingHapticsTask = Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .soft)

            while !Task.isCancelled {
                generator.prepare()
                generator.impactOccurred(intensity: 0.35)

                do {
                    try await Task.sleep(for: .milliseconds(950))
                } catch {
                    break
                }
            }
        }
    }

    private func stopThinkingHaptics() {
        thinkingHapticsTask?.cancel()
        thinkingHapticsTask = nil
    }
}

private struct DayAnalysisMessageView: View {
    let message: DayAnalysisMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 48)
            }

            Text(message.text)
                .font(.system(size: message.role == .user ? 22 : 21, weight: message.role == .user ? .medium : .regular, design: .rounded))
                .lineSpacing(2)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, message.role == .user ? 14 : 0)
                .padding(.vertical, message.role == .user ? 10 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(message.role == .user ? Color.primary.opacity(0.08) : Color.clear)
                )
                .contentTransition(.numericText())

            if message.role == .assistant {
                Spacer(minLength: 24)
            }
        }
        .animation(.snappy(duration: 0.25), value: message.text)
    }
}
