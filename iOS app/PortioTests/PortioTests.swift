//
//  PortioTests.swift
//  PortioTests
//
//  Created by Иван on 12.10.2025.
//

import Testing
import Foundation
import SwiftData
@testable import Portio

struct PortioTests {

    @Test func processingItemCanOnlyBeClaimedByOneJob() async throws {
        let item = FoodItem(name: "banana")
        let foregroundJob = "foreground-\(UUID().uuidString)"
        let backgroundJob = "background-\(UUID().uuidString)"

        #expect(item.claimProcessingJob(id: foregroundJob, at: .now))
        #expect(!item.claimProcessingJob(id: backgroundJob, at: .now))
        #expect(item.processingJobId == foregroundJob)
        #expect(item.isProcessing)
        #expect(!item.hasFailedProcessing)
    }

    @Test func failedProcessingKeepsOriginalQueryForRetry() async throws {
        let item = FoodItem(name: "two eggs")

        item.markProcessingFailed("Network unavailable")

        #expect(!item.isProcessing)
        #expect(item.hasFailedProcessing)
        #expect(item.processingErrorMessage == "Network unavailable")
        #expect(item.name == "two eggs")
        #expect(item.cleanFoodName == "two eggs")
    }

    @Test func manualFoodEntryCreatesCompletedFoodItem() async throws {
        let entry = ManualFoodEntry(
            name: "Greek yogurt",
            weightGrams: 170,
            calories: 120,
            protein: 18,
            carbs: 7,
            fat: 3
        )

        let item = entry.makeFoodItem(loggedAt: try #require(DateComponents(calendar: .current, year: 2026, month: 6, day: 14).date))

        #expect(item.name == "Greek yogurt")
        #expect(item.identifiedFood == "Greek yogurt")
        #expect(item.cleanFoodName == "Greek yogurt")
        #expect(!item.isProcessing)
        #expect(item.dataSource == "Manual")
        #expect(item.weightGrams == 170)
        #expect(item.caloriesPer100g == 120 / 1.7)
        #expect(item.proteinPer100g == 18 / 1.7)
        #expect(item.carbsPer100g == 7 / 1.7)
        #expect(item.fatPer100g == 3 / 1.7)
    }

    @Test func strictManualToolCallParserRejectsFinalNutritionJSON() async throws {
        let finalNutrition = #"{"foods":[{"name":"not a tool","parameters":{"query":"looks tempting"}}]}"#

        #expect(NutritionService.extractManualToolCall(from: finalNutrition) == nil)
    }

    @Test func strictManualToolCallParserAcceptsSingleKnownToolCall() async throws {
        let content = #"{"name":"google_search","parameters":{"query":"Big Mac nutrition facts"}}"#

        let toolCall = NutritionService.extractManualToolCall(from: content)

        #expect(toolCall?.function.name == "google_search")
        #expect(toolCall?.function.arguments == #"{"query":"Big Mac nutrition facts"}"#)
    }

    @Test func initialNutritionPassAllowsDirectJSONOrSearchTools() async throws {
        let prompt = NutritionService.initialSystemPromptForTesting

        #expect(prompt.contains("If the food is generic, unbranded, and you can estimate it reliably, output the final JSON immediately"))
        #expect(prompt.contains("If the item is branded, packaged, restaurant-made, regional, ambiguous, or uncertain, use tools before final JSON"))
        #expect(!prompt.contains("Do not output final JSON until after you have used the required tools"))
    }

    @Test func requiredToolChoiceEncodesOpenAICompatibleValue() throws {
        let encoded = try JSONEncoder().encode(OpenRouterRequest.ToolChoice.required)
        let value = String(data: encoded, encoding: .utf8)

        #expect(value == #""required""#)
    }

    @Test func imageInitialPassAllowsVisionModelToAnswerBeforeTools() throws {
        let encoded = try JSONEncoder().encode(
            NutritionService.initialToolChoiceForTesting(hasImages: true)
        )
        let value = String(data: encoded, encoding: .utf8)

        #expect(value == #""auto""#)
    }

    @Test func textOnlyInitialPassAllowsModelToAnswerOrSearch() throws {
        let encoded = try JSONEncoder().encode(
            NutritionService.initialToolChoiceForTesting(hasImages: false)
        )
        let value = String(data: encoded, encoding: .utf8)

        #expect(value == #""auto""#)
    }

    @Test func finalNutritionResponseWithoutToolCallsIsAccepted() {
        #expect(NutritionService.canAcceptFinalResponseForTesting(hasExecutedTools: false, hasImages: true))
        #expect(NutritionService.canAcceptFinalResponseForTesting(hasExecutedTools: false, hasImages: false))
        #expect(NutritionService.canAcceptFinalResponseForTesting(hasExecutedTools: true, hasImages: false))
    }

    @Test func continuedProcessingTaskUsesSeparateUserInitiatedIdentifier() {
        #expect(BackgroundTaskManager.processingTaskIdentifier == "com.ivan.Portio.nutrition-processing")
        #expect(BackgroundTaskManager.continuedProcessingTaskIdentifier == "com.ivan.Portio.nutrition-continued-processing")
    }

    @Test func continuedProcessingProgressSubtitleDescribesCompletedRecords() {
        #expect(BackgroundTaskManager.continuedProcessingSubtitle(completed: 0, total: 3) == "0 of 3 records processed")
        #expect(BackgroundTaskManager.continuedProcessingSubtitle(completed: 3, total: 3) == "3 of 3 records processed")
    }

    @Test func foodItemDaySelectionFiltersSelectedDayNewestFirst() throws {
        let calendar = Calendar(identifier: .gregorian)
        let selectedMorning = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 8)))
        let selectedEvening = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 20)))
        let otherDay = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 12)))

        let selectedItems = FoodItemDaySelection.items(
            from: [
                makeFoodItem(named: "Tomorrow", date: otherDay),
                makeFoodItem(named: "Dinner", date: selectedEvening),
                makeFoodItem(named: "Breakfast", date: selectedMorning)
            ],
            on: selectedMorning,
            calendar: calendar
        )

        #expect(selectedItems.map(\.name) == ["Dinner", "Breakfast"])
    }

    @Test func foodItemDaySelectionFormatsTodayTitleAndDetectsToday() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 13)))
        let yesterday = try #require(calendar.date(from: DateComponents(year: 2026, month: 6, day: 12)))

        #expect(FoodItemDaySelection.isToday(today, now: today, calendar: calendar))
        #expect(!FoodItemDaySelection.isToday(yesterday, now: today, calendar: calendar))
        #expect(FoodItemDaySelection.title(for: today, now: today, calendar: calendar, locale: Locale(identifier: "en_US")) == "Today, Jun 13")
        #expect(FoodItemDaySelection.title(for: yesterday, now: today, calendar: calendar, locale: Locale(identifier: "en_US")) == "Jun 12")
    }

    @MainActor
    @Test func sharedDataManagerCreatesContainerWithCurrentSchema() throws {
        let container = try SharedDataManager.makeContainer(inMemory: true)
        let item = FoodItem(name: "banana")
        item.searchSteps = [
            SearchStep(
                query: "banana nutrition",
                results: [SearchResult(title: "Banana", link: "https://example.com", snippet: "Nutrition facts")]
            )
        ]
        item.markProcessingFailed("Network unavailable")

        container.mainContext.insert(item)
        try container.mainContext.save()

        let items = try container.mainContext.fetch(FetchDescriptor<FoodItem>())
        #expect(items.first?.searchSteps.first?.query == "banana nutrition")
        #expect(items.first?.processingErrorMessage == "Network unavailable")
    }

    private func makeFoodItem(named name: String, date: Date) -> FoodItem {
        FoodItem(
            name: name,
            identifiedFood: name,
            cleanFoodName: name,
            dateEaten: date,
            calories: 100,
            protein: 10,
            carbs: 10,
            fat: 5,
            weightGrams: 100,
            caloriesPer100g: 100,
            proteinPer100g: 10,
            carbsPer100g: 10,
            fatPer100g: 5
        )
    }
}
