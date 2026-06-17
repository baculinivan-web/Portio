import Testing
import Foundation
@testable import Portio

struct DayAnalysisContextTests {
    @MainActor @Test func contextUsesOnlyCompletedItemsForSelectedDay() throws {
        let calendar = Calendar(identifier: .gregorian)
        let selectedDay = try #require(DateComponents(calendar: calendar, year: 2026, month: 6, day: 17, hour: 12).date)
        let sameDay = try #require(DateComponents(calendar: calendar, year: 2026, month: 6, day: 17, hour: 8).date)
        let yesterday = try #require(DateComponents(calendar: calendar, year: 2026, month: 6, day: 16, hour: 22).date)

        let completedToday = FoodItem(
            name: "oreo ice cream",
            identifiedFood: "Oreo ice cream",
            cleanFoodName: "Oreo ice cream",
            dateEaten: sameDay,
            isProcessing: false,
            dataSource: "Google",
            calories: 350,
            protein: 4,
            carbs: 47,
            fat: 11,
            weightGrams: 80,
            caloriesPer100g: 437.5,
            proteinPer100g: 5,
            carbsPer100g: 58.75,
            fatPer100g: 13.75
        )
        let processingToday = FoodItem(name: "pizza")
        processingToday.dateEaten = sameDay
        let failedToday = FoodItem(name: "unknown snack")
        failedToday.dateEaten = sameDay
        failedToday.markProcessingFailed("No nutrition data was returned.")
        let completedYesterday = FoodItem(
            name: "banana",
            identifiedFood: "Banana",
            cleanFoodName: "Banana",
            dateEaten: yesterday,
            calories: 90,
            protein: 1,
            carbs: 23,
            fat: 0,
            weightGrams: 110,
            caloriesPer100g: 82,
            proteinPer100g: 0.9,
            carbsPer100g: 21,
            fatPer100g: 0
        )

        let context = DayAnalysisContext.make(
            selectedDate: selectedDay,
            items: [completedToday, processingToday, failedToday, completedYesterday],
            calorieGoal: 2930,
            proteinGoal: 135,
            carbsGoal: 406,
            fatGoal: 85,
            weightGoalMode: .gain,
            goalExplanation: "Gain weight steadily",
            calendar: calendar
        )

        #expect(context.entries.map(\.name) == ["Oreo ice cream"])
        #expect(context.totals.calories == 350)
        #expect(context.totals.protein == 4)
        #expect(context.totals.carbs == 47)
        #expect(context.totals.fat == 11)
        #expect(context.goals.calories == 2930)
        #expect(context.goals.weightGoalMode == "Gain Weight")
    }

    @MainActor @Test func promptIncludesGoalsTotalsAndFoodEntries() throws {
        let calendar = Calendar(identifier: .gregorian)
        let selectedDay = try #require(DateComponents(calendar: calendar, year: 2026, month: 6, day: 17, hour: 12).date)
        let item = FoodItem(
            name: "oreo ice cream",
            identifiedFood: "Oreo ice cream 80g",
            cleanFoodName: "Oreo ice cream",
            dateEaten: selectedDay,
            isProcessing: false,
            dataSource: "Google",
            calories: 350,
            protein: 4,
            carbs: 47,
            fat: 11,
            weightGrams: 80,
            caloriesPer100g: 437.5,
            proteinPer100g: 5,
            carbsPer100g: 58.75,
            fatPer100g: 13.75
        )

        let context = DayAnalysisContext.make(
            selectedDate: selectedDay,
            items: [item],
            calorieGoal: 2930,
            proteinGoal: 135,
            carbsGoal: 406,
            fatGoal: 85,
            weightGoalMode: .gain,
            goalExplanation: "Gain weight steadily",
            calendar: calendar
        )

        let prompt = DayAnalysisPromptBuilder.summaryPrompt(for: context)

        #expect(prompt.contains("calorie goal: 2930 kcal"))
        #expect(prompt.contains("current totals: 350 kcal, protein 4 g, carbs 47 g, fat 11 g"))
        #expect(prompt.contains("Oreo ice cream"))
        #expect(prompt.contains("80 g"))
        #expect(prompt.contains("what food they should avoid today and what to replace it with"))
    }
}
