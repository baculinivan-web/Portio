//
//  PortioTests.swift
//  PortioTests
//
//  Created by Иван on 12.10.2025.
//

import Testing
import Foundation
import SwiftData
import BackgroundTasks
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
        #expect(prompt.contains("If native tool-calling is unavailable"))
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

    @Test func imageInitialPassDoesNotAttachNativeTools() {
        #expect(!NutritionService.shouldSendNativeToolsForTesting(hasExecutedTools: false, hasImages: true))
        #expect(NutritionService.shouldSendNativeToolsForTesting(hasExecutedTools: false, hasImages: false))
        #expect(NutritionService.shouldSendNativeToolsForTesting(hasExecutedTools: true, hasImages: false))
    }

    @Test func finalNutritionResponseWithoutToolCallsIsAccepted() {
        #expect(NutritionService.canAcceptFinalResponseForTesting(hasExecutedTools: false, hasImages: true))
        #expect(NutritionService.canAcceptFinalResponseForTesting(hasExecutedTools: false, hasImages: false))
        #expect(NutritionService.canAcceptFinalResponseForTesting(hasExecutedTools: true, hasImages: false))
    }

    @Test func nutritionPassDisablesMoreToolCallsAfterToolsWereExecuted() throws {
        let encoded = try JSONEncoder().encode(
            NutritionService.toolChoiceForTesting(hasExecutedTools: true, hasImages: false)
        )
        let value = String(data: encoded, encoding: .utf8)

        #expect(value == #""none""#)
    }

    @Test func openAICompatibleRetryPolicyRetriesTransientFailuresOnly() {
        let policy = OpenAICompatibleRetryPolicy(maxAttempts: 3, baseDelayNanoseconds: 1)

        #expect(policy.shouldRetry(.httpStatus(429, retryAfterSeconds: nil), attempt: 1))
        #expect(policy.shouldRetry(.httpStatus(503, retryAfterSeconds: 2), attempt: 2))
        #expect(policy.shouldRetry(.transport(URLError(.timedOut)), attempt: 1))
        #expect(!policy.shouldRetry(.httpStatus(401, retryAfterSeconds: nil), attempt: 1))
        #expect(!policy.shouldRetry(.httpStatus(400, retryAfterSeconds: nil), attempt: 1))
        #expect(!policy.shouldRetry(.invalidJSON("bad shape"), attempt: 1))
        #expect(!policy.shouldRetry(.httpStatus(503, retryAfterSeconds: nil), attempt: 3))
    }

    @Test func openAICompatibleRetryPolicyUsesRetryAfterBeforeBackoff() {
        let policy = OpenAICompatibleRetryPolicy(maxAttempts: 3, baseDelayNanoseconds: 10)

        #expect(policy.delayNanoseconds(for: .httpStatus(429, retryAfterSeconds: 2), attempt: 1) == 2_000_000_000)
        #expect(policy.delayNanoseconds(for: .httpStatus(503, retryAfterSeconds: nil), attempt: 2) == 20)
    }

    @MainActor
    @Test func jsonSchemaResponseFormatEncodesOpenAICompatiblePayload() throws {
        let schema: [String: JSONValue] = [
            "type": .string("object"),
            "properties": .object([
                "foods": .object([
                    "type": .string("array")
                ])
            ]),
            "required": .array([.string("foods")]),
            "additionalProperties": .bool(false)
        ]

        let encoded = try JSONEncoder().encode(
            OpenAICompatibleResponseFormat.jsonSchema(name: "nutrition_response", schema: schema, strict: true)
        )
        let json = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        let jsonSchema = try #require(json["json_schema"] as? [String: Any])

        #expect(json["type"] as? String == "json_schema")
        #expect(jsonSchema["name"] as? String == "nutrition_response")
        #expect(jsonSchema["strict"] as? Bool == true)
        #expect(jsonSchema["schema"] != nil)
    }

    @Test func finalNutritionPassDoesNotTreatContentAsManualToolCall() {
        let content = #"{"name":"google_search","parameters":{"query":"more nutrition facts"}}"#

        #expect(
            NutritionService.extractManualToolCallForTesting(
                from: content,
                hasExecutedTools: true
            ) == nil
        )
        #expect(
            NutritionService.extractManualToolCallForTesting(
                from: content,
                hasExecutedTools: false
            )?.function.name == "google_search"
        )
    }

    @Test func googleSearchResultsArePreservedWhenFinalJSONForgetsGroundingFlag() async throws {
        var chatRequestCount = 0
        NutritionServiceURLProtocolMock.requestHandler = { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            if url.host == "api.example.test" {
                chatRequestCount += 1
                if chatRequestCount == 1 {
                    return Self.jsonResponse(
                        for: request,
                        body: Self.chatResponse(
                            message: [
                                "content": NSNull(),
                                "tool_calls": [
                                    [
                                        "id": "call_google",
                                        "type": "function",
                                        "function": [
                                            "name": "google_search",
                                            "arguments": #"{"query":"big mac nutrition facts"}"#
                                        ]
                                    ]
                                ]
                            ]
                        )
                    )
                }

                return Self.jsonResponse(
                    for: request,
                    body: Self.chatResponse(
                        content: """
                        {"foods":[{"identifiedFood":"Big Mac","cleanFoodName":"Big Mac","calories":590,"protein":25,"carbs":46,"fat":34,"estimatedWeightGrams":219,"caloriesPer100g":269.4,"proteinPer100g":11.4,"carbsPer100g":21,"fatPer100g":15.5,"isSearchGrounded":false,"dataSource":null}]}
                        """
                    )
                )
            }

            if url.host == "google.serper.dev" {
                #expect(request.value(forHTTPHeaderField: "X-API-KEY") == "serper-key")
                return Self.jsonResponse(
                    for: request,
                    body: """
                    {
                      "answerBox": {"answer": "A Big Mac has 590 calories."},
                      "organic": [
                        {
                          "title": "Big Mac Nutrition Facts",
                          "link": "https://example.test/big-mac",
                          "snippet": "Big Mac nutrition information from the menu."
                        }
                      ]
                    }
                    """
                )
            }

            throw URLError(.unsupportedURL)
        }
        URLProtocol.registerClass(NutritionServiceURLProtocolMock.self)
        defer {
            URLProtocol.unregisterClass(NutritionServiceURLProtocolMock.self)
            NutritionServiceURLProtocolMock.requestHandler = nil
        }

        let service = NutritionService(
            apiKey: "test-key",
            modelName: "test-model",
            serperApiKey: "  serper-key  ",
            customBaseURL: "https://api.example.test/v1",
            provider: .custom
        )

        let foods = try await service.fetchNutrition(for: "Big Mac")
        let food = try #require(foods.first)

        #expect(food.isSearchGrounded == true)
        #expect(food.dataSource == "Google")
        #expect(food.searchSteps?.first?.query == "big mac nutrition facts")
        #expect(food.searchSteps?.first?.answerBox == "A Big Mac has 590 calories.")
    }

    @Test func continuedProcessingTaskUsesSeparateUserInitiatedIdentifier() {
        #expect(BackgroundTaskManager.processingTaskIdentifier == "com.ivan.Portio.nutrition-processing")
        #expect(BackgroundTaskManager.continuedProcessingTaskIdentifier == "com.ivan.Portio.nutrition-continued-processing")
    }

    @Test func continuedProcessingProgressSubtitleDescribesCompletedRecords() {
        #expect(BackgroundTaskManager.continuedProcessingSubtitle(completed: 0, total: 3) == "0 of 3 records processed")
        #expect(BackgroundTaskManager.continuedProcessingSubtitle(completed: 3, total: 3) == "3 of 3 records processed")
    }

    @Test func foregroundWorkerOnlyStartsWhenContinuedProcessingIsUnavailable() {
        #expect(!BackgroundTaskManager.shouldStartForegroundWorker(continuedProcessingSubmitted: true))
        #expect(BackgroundTaskManager.shouldStartForegroundWorker(continuedProcessingSubmitted: false))
    }

    @available(iOS 26.0, *)
    @Test func continuedProcessingUsesFailFastSubmissionForUserInitiatedWork() {
        #expect(BackgroundTaskManager.continuedProcessingSubmissionStrategyForTesting == .fail)
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

    private static func jsonResponse(for request: URLRequest, body: String, statusCode: Int = 200) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, Data(body.utf8))
    }

    private static func chatResponse(content: String) -> String {
        chatResponse(message: ["content": content])
    }

    private static func chatResponse(message: [String: Any]) -> String {
        let payload: [String: Any] = [
            "choices": [
                [
                    "finish_reason": "stop",
                    "message": message
                ]
            ]
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload)
        return String(data: data, encoding: .utf8)!
    }
}

private final class NutritionServiceURLProtocolMock: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        guard let host = request.url?.host else { return false }
        return ["api.example.test", "google.serper.dev"].contains(host)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
