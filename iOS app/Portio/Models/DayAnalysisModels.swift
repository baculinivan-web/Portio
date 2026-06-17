import Foundation

struct DayAnalysisContext: Equatable {
    var date: Date
    var goals: DayAnalysisGoals
    var totals: DayAnalysisTotals
    var entries: [DayAnalysisEntry]
    var goalExplanation: String

    @MainActor static func make(
        selectedDate: Date,
        items: [FoodItem],
        calorieGoal: Double,
        proteinGoal: Double,
        carbsGoal: Double,
        fatGoal: Double,
        weightGoalMode: UserSettings.WeightGoalMode,
        goalExplanation: String,
        calendar: Calendar = .current
    ) -> DayAnalysisContext {
        let entries = items
            .filter { item in
                calendar.isDate(item.dateEaten, inSameDayAs: selectedDate)
                    && !item.isProcessing
                    && !item.hasFailedProcessing
            }
            .map(DayAnalysisEntry.init)

        let totals = entries.reduce(DayAnalysisTotals.zero) { partial, entry in
            DayAnalysisTotals(
                calories: partial.calories + entry.calories,
                protein: partial.protein + entry.protein,
                carbs: partial.carbs + entry.carbs,
                fat: partial.fat + entry.fat
            )
        }

        return DayAnalysisContext(
            date: selectedDate,
            goals: DayAnalysisGoals(
                calories: calorieGoal,
                protein: proteinGoal,
                carbs: carbsGoal,
                fat: fatGoal,
                weightGoalMode: weightGoalMode.rawValue
            ),
            totals: totals,
            entries: entries,
            goalExplanation: goalExplanation
        )
    }
}

struct DayAnalysisGoals: Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var weightGoalMode: String
}

struct DayAnalysisTotals: Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let zero = DayAnalysisTotals(calories: 0, protein: 0, carbs: 0, fat: 0)
}

struct DayAnalysisEntry: Equatable, Identifiable {
    var id: UUID
    var name: String
    var originalQuery: String
    var identifiedFood: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var weightGrams: Double
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var dataSource: String?

    @MainActor init(item: FoodItem) {
        id = item.id
        name = item.cleanFoodName
        originalQuery = item.name
        identifiedFood = item.identifiedFood
        calories = item.calories
        protein = item.protein
        carbs = item.carbs
        fat = item.fat
        weightGrams = item.weightGrams
        caloriesPer100g = item.caloriesPer100g
        proteinPer100g = item.proteinPer100g
        carbsPer100g = item.carbsPer100g
        fatPer100g = item.fatPer100g
        dataSource = item.dataSource
    }
}

struct DayAnalysisResult: Codable, Equatable {
    var summary: String
    var avoid: String
    var replacement: String

    var chatSeedText: String {
        [summary, avoid, replacement]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    var plainText: DayAnalysisResult {
        DayAnalysisResult(
            summary: DayAnalysisTextSanitizer.plainText(summary),
            avoid: DayAnalysisTextSanitizer.plainText(avoid),
            replacement: DayAnalysisTextSanitizer.plainText(replacement)
        )
    }
}

struct DayAnalysisMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    var id = UUID()
    var role: Role
    var text: String
    var date = Date()
}

enum DayAnalysisPromptBuilder {
    static func summaryPrompt(for context: DayAnalysisContext) -> String {
        """
        Analyze today's food log and goal impact.

        User goal:
        - mode: \(context.goals.weightGoalMode)
        - calorie goal: \(format(context.goals.calories)) kcal
        - protein goal: \(format(context.goals.protein)) g
        - carbs goal: \(format(context.goals.carbs)) g
        - fat goal: \(format(context.goals.fat)) g
        - explanation: \(context.goalExplanation.isEmpty ? "not provided" : context.goalExplanation)

        Today:
        - current totals: \(format(context.totals.calories)) kcal, protein \(format(context.totals.protein)) g, carbs \(format(context.totals.carbs)) g, fat \(format(context.totals.fat)) g

        Entries:
        \(entriesText(context.entries))

        Return ONLY a minified JSON object with these string keys:
        - "summary": short analysis of the day so far and how it affects the user goal
        - "avoid": what food they should avoid today and what to replace it with
        - "replacement": a specific replacement recommendation

        Keep each value short, direct, and natural. Do not use markdown, headings, bullet lists, numbered lists, bold text, asterisks, backticks, or tables.
        """
    }

    static func chatPrompt(question: String, context: DayAnalysisContext, history: [DayAnalysisMessage]) -> String {
        """
        Answer the user's question about today's food log.

        User goal:
        - mode: \(context.goals.weightGoalMode)
        - calorie goal: \(format(context.goals.calories)) kcal
        - protein goal: \(format(context.goals.protein)) g
        - carbs goal: \(format(context.goals.carbs)) g
        - fat goal: \(format(context.goals.fat)) g
        - explanation: \(context.goalExplanation.isEmpty ? "not provided" : context.goalExplanation)

        Today:
        - current totals: \(format(context.totals.calories)) kcal, protein \(format(context.totals.protein)) g, carbs \(format(context.totals.carbs)) g, fat \(format(context.totals.fat)) g

        Entries:
        \(entriesText(context.entries))

        Recent chat:
        \(historyText(history))

        User question: \(question)

        Answer in plain text only. Do not use markdown, headings, bullet lists, bold text, asterisks, backticks, or tables.
        If structure helps, use a short numbered list exactly like "1. ...", "2. ...", "3. ...".
        Do not repeat the analysis already present in recent chat. Answer the new question directly.
        Be concise but useful.
        """
    }

    private static func entriesText(_ entries: [DayAnalysisEntry]) -> String {
        guard !entries.isEmpty else { return "- no completed entries yet" }

        return entries.map { entry in
            "- \(entry.name): \(format(entry.weightGrams)) g, \(format(entry.calories)) kcal, protein \(format(entry.protein)) g, carbs \(format(entry.carbs)) g, fat \(format(entry.fat)) g, per 100g \(format(entry.caloriesPer100g)) kcal / P \(format(entry.proteinPer100g)) g / C \(format(entry.carbsPer100g)) g / F \(format(entry.fatPer100g)) g, source \(entry.dataSource ?? "internal")"
        }
        .joined(separator: "\n")
    }

    private static func historyText(_ history: [DayAnalysisMessage]) -> String {
        guard !history.isEmpty else { return "- none" }

        let relevantHistory: [DayAnalysisMessage]
        if history.count > 6, history.first?.role == .assistant {
            relevantHistory = [history[0]] + history.suffix(5)
        } else {
            relevantHistory = Array(history.suffix(6))
        }

        return relevantHistory.map { message in
            "- \(message.role.rawValue): \(message.text)"
        }
        .joined(separator: "\n")
    }

    private static func format(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.05 {
            return String(format: "%.0f", rounded)
        }
        return String(format: "%.1f", value)
    }
}

enum DayAnalysisTextSanitizer {
    static func plainText(_ text: String) -> String {
        let withoutInlineMarkers = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "#", with: "")

        return withoutInlineMarkers
            .components(separatedBy: .newlines)
            .map { line in
                var cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
                while cleaned.hasPrefix("- ") || cleaned.hasPrefix("* ") || cleaned.hasPrefix("• ") {
                    cleaned = String(cleaned.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return cleaned
            }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
