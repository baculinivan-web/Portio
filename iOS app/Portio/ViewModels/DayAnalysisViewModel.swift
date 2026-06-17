import Foundation
import SwiftUI
import Combine

@MainActor
final class DayAnalysisViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case loadingSummary
        case ready
        case asking
        case failed(String)

        var isLoading: Bool {
            switch self {
            case .loadingSummary, .asking:
                return true
            case .idle, .ready, .failed:
                return false
            }
        }
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var result: DayAnalysisResult?
    @Published private(set) var messages: [DayAnalysisMessage] = []

    private var loadedContextSignature: String?

    private var nutritionService: NutritionService {
        let apiKey = UserSettings.openRouterApiKey.isEmpty
            ? (APIKeyManager.getOpenRouterAPIKey() ?? "")
            : UserSettings.openRouterApiKey
        let serperKey = UserSettings.serperApiKey.isEmpty
            ? (APIKeyManager.getSerperAPIKey() ?? "")
            : UserSettings.serperApiKey

        let model: String
        let customBaseURL: String?
        let provider = UserSettings.llmProvider

        if provider == .blockRun {
            model = UserSettings.modelName.isEmpty ? "nvidia/mistral-small-4-119b" : UserSettings.modelName
            customBaseURL = nil
        } else {
            model = UserSettings.modelName.isEmpty
                ? (APIKeyManager.getModelName() ?? "openai/gpt-oss-120b:free")
                : UserSettings.modelName
            customBaseURL = UserSettings.customApiBaseUrl
        }

        return NutritionService(apiKey: apiKey, modelName: model, serperApiKey: serperKey, customBaseURL: customBaseURL, provider: provider)
    }

    func resetIfNeeded(for context: DayAnalysisContext) {
        let signature = Self.signature(for: context)
        guard loadedContextSignature != nil, loadedContextSignature != signature else { return }

        result = nil
        messages = []
        status = .idle
        loadedContextSignature = nil
    }

    func loadIfNeeded(context: DayAnalysisContext) {
        let signature = Self.signature(for: context)
        guard loadedContextSignature != signature else { return }
        guard !status.isLoading else { return }

        status = .loadingSummary
        loadedContextSignature = signature

        Task {
            do {
                result = try await nutritionService.fetchDayAnalysis(context: context)
                status = .ready
            } catch {
                status = .failed(error.localizedDescription)
            }
        }
    }

    func retry(context: DayAnalysisContext) {
        loadedContextSignature = nil
        loadIfNeeded(context: context)
    }

    func ask(_ question: String, context: DayAnalysisContext) {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty, !status.isLoading else { return }

        var historyBeforeQuestion = messages
        if let analysis = result?.chatSeedText, !analysis.isEmpty {
            historyBeforeQuestion.insert(
                DayAnalysisMessage(role: .assistant, text: analysis),
                at: 0
            )
        }
        messages.append(DayAnalysisMessage(role: .user, text: trimmedQuestion))
        status = .asking

        Task {
            do {
                let answer = try await nutritionService.askDayAnalysis(
                    question: trimmedQuestion,
                    context: context,
                    history: historyBeforeQuestion
                )
                messages.append(DayAnalysisMessage(role: .assistant, text: answer))
                status = .ready
            } catch {
                messages.append(DayAnalysisMessage(role: .assistant, text: error.localizedDescription))
                status = .failed(error.localizedDescription)
            }
        }
    }

    private static func signature(for context: DayAnalysisContext) -> String {
        let entrySignature = context.entries
            .map { "\($0.id.uuidString):\($0.calories):\($0.protein):\($0.carbs):\($0.fat)" }
            .joined(separator: "|")

        return [
            "\(Calendar.current.startOfDay(for: context.date).timeIntervalSince1970)",
            "\(context.goals.calories)",
            "\(context.goals.protein)",
            "\(context.goals.carbs)",
            "\(context.goals.fat)",
            entrySignature
        ].joined(separator: "#")
    }
}
